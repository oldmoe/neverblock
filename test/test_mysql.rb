require 'rubygems'
require 'neverblock'
require 'neverblock-mysql'

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
