require 'rubygems'
require 'neverblock'
require 'neverblock-pg'

$fpool = NB::Pool::FiberPool.new(50)

$long_count = ARGV[0].to_i
$freq = ARGV[1].to_i
$done = false

$connections = {}
$sockets = []
$cpool = NB::Pool::FiberedConnectionPool.new(:size=>10, :eager=>true) {
  conn = NB::DB::FPGconn.new({:host=>'localhost',:user=>'postgres',:dbname=>'evented'})
  $sockets << socket = IO.new(conn.socket)
	$connections[socket] = conn
}

def $cpool.exec(sql)
  hold do |conn|
    conn.exec(sql)
  end
end

def $cpool.[](sql)
  self.exec(sql)
end

def $cpool.begin_db_transaction
  hold(true) do |conn|
    conn.exec("begin")
  end
end
def $cpool.rollback_db_transaction
  hold do |conn|
    conn.exec("rollback")
    release(Fiber.current,conn)
  end
end
def $cpool.commit_db_transaction
  hold do |conn|
    conn.exec("commit")
    release(Fiber.current,conn)
  end
end

$long_query = "select sleep(1)"
$short_query = "select 1"

def run_blocking
  t = Time.now
  $long_count.times do |i|
		  $cpool[$long_query]
		  $freq.times do |j|
				  $cpool[$short_query].each{|r|r}
		  end
  end
  Time.now - t
end
print "finished blocking queries in : "
puts $b_time = run_blocking

def run_evented
	$count = 0
	$count_long = 0
	$finished = 0
	$long_count.times do |i|
		$fpool.spawn do
      $cpool[$long_query].each{|r|r}
			$finished = $finished + 1
			if $finished == ($long_count * ($freq+1))
				puts ($e_l_time = Time.now - $t)
				puts "advantage = #{(100 - ( $e_l_time / $b_time ) * 100).to_i}%"
				stop_loop
			end
		end
		$freq.times do |j|
			$fpool.spawn do
				$cpool[$short_query].each{|r|r}
        $finished = $finished + 1
				if $finished == ($long_count * ($freq+1))
					puts ($e_l_time = Time.now - $t)
					puts "advantage = #{(100 - ( $e_l_time / $b_time ) * 100).to_i}%"
					stop_loop
				end
			end
		end
	end
end

def stop_loop
	$done = true
end

$t = Time.now
print "finished evented queries in : "
run_evented
loop do
	res = select($sockets,nil,nil,nil)
	res.first.each{ |s|$connections[s].resume_command } if res
	break if $done
end
