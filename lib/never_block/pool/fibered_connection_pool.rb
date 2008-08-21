# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2008 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

module NeverBlock
  module Pool
    
    # Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
    # Copyright:: Copyright (c) 2008 eSpace, Inc.
    # License::   Distributes under the same terms as Ruby
    #
		# This class represents a pool of connections, 
		# you hold or release conncetions from the pool
		# hold requests that cannot be fullfiled will be queued
		# the fiber will be paused and resumed later when
		# a connection is avaialble
		#
		# Large portions of this class were copied and pasted
		# form Sequel's threaded connection pool
    #
    # Example:
    #
    # pool = NeverBlock::Pool::FiberedConnectionPool.new(:size=>16)do
    #   # connection creation code goes here   
    # end
    # 32.times do
    #   Fiber.new do
    #     conn = pool.hold # hold will pause the fiber until a connection is available
    #     conn.execute('something') # you can use the connection normally now 
    #   end.resume
    # end
    # 
    # The pool has support for transactions, just pass true to the pool#hold method
    # and the connection will not be released after the block is finished
    # It is the responsibility of client code to release the connection
		class FiberedConnectionPool
       
      # initialize the connection pool
      # using the supplied proc to create the connections
      # you can choose to start them eagerly or lazily (lazy by default)     
			def initialize(options = {}, &block)
				@connections, @busy_connections, @queue = [], {},[]
				@connection_proc = block
				@size = options[:size] || 8
				if options[:eager]
				  @size.times do
				    @connections << @connection_proc.call
				  end  
				end
			end

      # If a connection is available,
      # pass it to the block, otherwise 
      # pass the fiber to the queue
      # till a connection is available
      # when done with a connection
      # try to porcess other fibers in the queue
      # before releasing the connection
      # if inside a transaction, don't release the fiber
			def hold(transactional = false)
			  fiber = Fiber.current
			  if conn = @busy_connections[fiber]
			    return yield(conn)
			  end
			  conn = acquire(fiber)
			  begin
			    yield conn
			  ensure
			    release(fiber, conn) unless transactional
					process_queue 
			  end
			end

      # Give the fiber back to the pool
      # you have to call this explicitly if
      # you held a connection for a transaction
			def release(fiber, conn)
				@busy_connections.delete(fiber)
				@connections << conn
			end
      
      private

      # Can we find a connection?
      # Can we create one?
      # Wait in the queue then
			def acquire(fiber)
				if !@connections.empty?
					@busy_connections[fiber] = @connections.shift
				elsif (@connections.length + @busy_connections.length) < @size
					conn = @connection_proc.call
					@busy_connections[fiber] = conn
				else
					Fiber.yield @queue << fiber
				end
			end

      # Check if there are waiting fibers and
      # try to process them
			def process_queue
				while !@connections.empty? and !@queue.empty?
					fiber = @queue.shift
					# What is really happening here?
					# we are resuming a fiber from within
					# another, should we call transfer insted?
					fiber.resume @busy_connections[fiber] = @connections.shift
				end
			end
			
		end #FiberedConnectionPool
		
	end #Pool

end #NeverBlock
