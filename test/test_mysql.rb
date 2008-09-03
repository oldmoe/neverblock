require 'neverblock-mysql'

class Mysql
  attr_accessor :fiber
  alias :old_query :query
  def query(sql)
    if Fiber.current[:neverblock]
      send_query(sql)
      @fiber = Fiber.current
      Fiber.yield
    else
      old_query(sql)
    end
  end

  def process_command
    @fiber.resume get_result
  end
end

@count = 10
@connections = {}
@fpool = NB::Pool::FiberPool.new(@count)
@cpool = NB::Pool::FiberedConnectionPool.new(size:@count, eager:true) do
   c = Mysql.real_connect('localhost','root',nil)
   @connections[IO.new(c.socket)] = c
   c
end

@break = false
@done = 0
@t = Time.now
@count.times do
  @fpool.spawn(false) do
    @cpool.hold do |conn|
      conn.query('select sleep(1)').each{|r| r}
      @done = @done + 1
      puts "done in #{Time.now - @t}" if @done == @count
    end
  end
end
@sockets = @connections.keys
loop do
  res = select(@sockets,nil,nil,nil)
  if res
    res.first.each{|c|@connections[c].process_command}
  end
end
