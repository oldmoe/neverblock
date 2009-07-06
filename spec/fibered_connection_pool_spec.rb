$:.unshift File.expand_path('..')
require 'lib/neverblock'

class MockConnection; end

describe NB::Pool::FiberedConnectionPool do
  before(:each) do
    @pool = NB::Pool::FiberedConnectionPool.new(:size => 10) do
      MockConnection.new
    end
  end

  it "should create all connections lazily by default" do
    @pool.instance_variable_get(:@connections).length.should == 0
    @pool.instance_variable_get(:@busy_connections).length.should == 0
  end

  it "should create all connections eagerly if specified" do
    @pool = NB::Pool::FiberedConnectionPool.new(:size => 10, :eager => true) do
      MockConnection.new
    end
    @pool.instance_variable_get(:@connections).length.should == 10
    @pool.instance_variable_get(:@busy_connections).length.should == 0
  end

  it "should create and yield a connection if :size not reached" do
    @pool.instance_variable_get(:@connections).length.should == 0
    @pool.instance_variable_get(:@busy_connections).length.should == 0

    @pool.hold {|conn| conn.should be_instance_of(MockConnection)}

    @pool.instance_variable_get(:@connections).length.should == 1
    @pool.instance_variable_get(:@busy_connections).length.should == 0
  end

  it "should create connections up to :size and queue other requests" do
    # prepate the fiber pool
    fpool = NB::Pool::FiberPool.new(15)
    fibers = []; fpool.fibers.each {|f| fibers << f}
    progress  = Array.new(15, false)

    # send 15 requests to the connection pool (of size 10)
    10.times do |i|
      fpool.spawn do
        @pool.hold do |conn|
          NB::Fiber.yield
          progress[i] = NB::Fiber.current #mark task finished
        end
      end
    end
    (10..14).each do |i|
      fpool.spawn do
        @pool.hold do |conn|
          progress[i] = NB::Fiber.current #mark task finished
        end
      end
    end

    # 10 requests should be in progress and 5 should be queued
    @pool.instance_variable_get(:@connections).length.should == 0
    @pool.instance_variable_get(:@busy_connections).length.should == 10
    @pool.instance_variable_get(:@queue).length.should == 5

    #resume first request which will finish it and will also handle the
    #queued requests
    fibers[0].resume
    [0,*10..14].each {|i| fibers[i].should == progress[i]}
    [*1..9].each do |i|
      progress[i].should == false
      fibers[i].resume
      progress[i].should == fibers[i]
    end
  end

  it "should use the same connection in a transaction" do
    #make sure there are more than one connection in the pool
    @pool = NB::Pool::FiberedConnectionPool.new(:size => 10, :eager => true) do
      MockConnection.new
    end
    fpool = NB::Pool::FiberPool.new(12)
    fibers = []; fpool.fibers.each {|f| fibers << f}
    t_conn = nil
    fpool.spawn do
      #announce the beginning of a transaction
      @pool.hold(true) {|conn| t_conn = conn}

      #another call to hold should get the same transaction's connection
      @pool.hold {|conn| t_conn.should == conn}

      #release the transaction connection
      @pool.hold do |conn|
        t_conn.should == conn
        @pool.release(NB::Fiber.current, conn)
      end

      #will now get a connection other than the transation's one (since there
      #are many connections. If there was only one then it would have been
      #returned anyways)
      @pool.hold {|conn| t_conn.should_not == conn}
    end
  end

  after(:each) do
    @pool = nil
  end
end
