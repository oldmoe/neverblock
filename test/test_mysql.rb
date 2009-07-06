require 'rubygems'
require 'neverblock'
require 'neverblock-mysql'

class Mysql
  attr_accessor :fiber
end

@count = 100
@fpool = NB::Pool::FiberPool.new(@count)
@cpool = NB::Pool::FiberedConnectionPool.new(size:@count, eager:true) do
   c = NB::DB::FiberedMysqlConnection.real_connect('localhost','root','root')
end

@break = false
@done = 0
@t = Time.now
@count.times do
  @fpool.spawn do
    @cpool.hold do |conn|              
      conn.send_query('select sleep(1) as sleep')
      io = IO.new(conn.socket)
      fiber = Fiber.current
      io.instance_variable_set(:@fiber, fiber)      
      NB::Reactor.reactor.attach(:read, io) do |s, r|
         r.detach(:read, s)
         fiber.resume
      end
      NB::Fiber.yield      
      a = conn.get_result #.each{|r|p r}
      @done = @done + 1
      puts "done in #{Time.now - @t}" if @done == @count
      NB::Reactor.stop if @done == @count
    end
  end
end

NB::Reactor.run
