require 'minitest/unit'
require File.expand_path(File.dirname(__FILE__)+'/../lib/neverblock/io/db/fibered_connection_pool')

MiniTest::Unit.autorun

class MySQLAdapterTest < MiniTest::Unit::TestCase
  def setup
    super
    require File.expand_path(File.dirname(__FILE__)+'/../lib/neverblock/io/db/drivers/mysql')
    @count = 20
  end
  
  def test_concurrent_processing
    cpool = []    
    
    @count.times do
     cpool << NB::DB::FiberedMysqlConnection.real_connect('localhost','root','home')
    end

    @done = 0
    t = Time.now
    NB.reactor.run do
      @count.times do |i|
        NB::Fiber.new do
          conn = cpool.shift
          conn.query('select sleep(0.1) as sleep')
          @done += 1
          if @done == @count
            NB.reactor.stop
          end
          conn.close
        end.resume
      end
    end    
    assert_in_delta Time.now - t, 0.1, 0.05
  end

  def test_pooled_concurrent_processing
    cpool = NB::Pool::FiberedConnectionPool.new(size:(@count/2).to_i, eager:true) do
      c = NB::DB::FiberedMysqlConnection.real_connect('localhost','root','home')
    end

    @done = 0
    t = Time.now
    NB.reactor.run do
      (@count).times do |i|
        NB::Fiber.new do
          cpool.hold do |conn|
            conn.query('select sleep(0.1) as sleep')
            @done += 1
            if @done == @count
              NB.reactor.stop
            end
          end
        end.resume
      end
    end
    assert_in_delta Time.now - t, 0.1, 0.15
  end


end
