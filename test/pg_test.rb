require 'minitest/unit'

MiniTest::Unit.autorun

class PGAdapterTest < MiniTest::Unit::TestCase
  def setup
    super
    require '../lib/neverblock'
    @count = 10
    @connection_proc = proc{NB::DB::FPGConn.new({:host=>'localhost',:user=>'postgres', :password=>'postgres',:dbname=>'postgres'})}
  end

  def test_concurrent_processing
    cpool = []    
    
    @count.times do
     cpool << @connection_proc.call
    end

    @done = 0
    t = Time.now
    NB.reactor.run do
      @count.times do |i|
        NB::Fiber.new do
          conn = cpool.shift
          conn.query('select sleep(1)'){}
          @done += 1          
          if @done == @count
            NB.reactor.stop
          end
          conn.close
        end.resume
      end
    end    
    assert_in_delta Time.now - t, 1, 0.5
  end

  def test_pooled_concurrent_processing
    cpool = NB::Pool::FiberedConnectionPool.new(size:(@count/2).to_i, eager:true) do
      @connection_proc.call
    end

    @done = 0
    t = Time.now
    NB.reactor.run do
      (@count).times do |i|
        NB::Fiber.new do
          cpool.hold do |conn|
            conn.query('select sleep(1)'){}
            @done += 1
            if @done == @count
              NB.reactor.stop
            end
          end
        end.resume
      end
    end
    assert_in_delta Time.now - t, 2, 0.5
  end
end
