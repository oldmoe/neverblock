require 'rubygems'
require 'neverblock'
require 'neverblock-mysql'

class Mysql
  attr_accessor :fiber
end

@count = 100
@connections = {}
@fpool = NB::Pool::FiberPool.new(@count)
@cpool = NB::Pool::FiberedConnectionPool.new(size:@count, eager:true) do
   c = NB::DB::FiberedMysqlConnection.real_connect('localhost','root',nil)
   @connections[c.io] = c
   c
end

@break = false
@done = 0
@t = Time.now
@count.times do
  @fpool.spawn do
    @cpool.hold do |conn|
      conn.query('select sleep(1) as sleep').each{|r|p r}
      @done = @done + 1
      puts "done in #{Time.now - @t}" if @done == @count
    end
  end
end
@sockets = @connections.keys
loop do
  res = select(@sockets,nil,nil,nil)
  if res
    res.first.each{|s|@connections[s].resume_command}
  end
end
