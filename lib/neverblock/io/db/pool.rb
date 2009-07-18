require File.expand_path(File.dirname(__FILE__)+'/../../../neverblock')

module NeverBlock
  module DB
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
    # pool = NeverBlock::Pool.new(:size=>16)do
    #   # connection creation code goes here   
    # end
    # 32.times do
    #   Fiber.new do
    #     # acquire a connection from the pool
    #     pool.hold do |conn|
    #       conn.execute('something') # you can use the connection normally now
    #     end
    #   end.resume
    # end
    # 
    # It is the responsibility of client code to release the connection
    # using pool.release(conn)
		class Pool

      attr_reader :size

      # initialize the connection pool using the supplied proc to create
      # the connections
      # You can choose to start them eagerly or lazily (lazy by default)
      # Available options are
      #   :size => the maximum number of connections to be created in the pool
      #   :eager => (true|false) indicates whether connections should be
      #             created initially or when need
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

      def replace_acquired_connection
        fiber = NB::Fiber.current
        conn = @connection_proc.call
        @busy_connections[fiber] = conn
        fiber[connection_pool_key] = conn
      end

      # If a connection is available, pass it to the block, otherwise pass
      # the fiber to the queue till a connection is available
			def hold
			  fiber = NB::Fiber.current
        conn = acquire(fiber)
        if block_given?
          yield conn
          release(conn)
        else
          conn
        end
			end

      # Give the fiber's connection back to the pool
			def release(conn)
			  @busy_connections.delete(conn.object_id)
			  @connections << conn unless @connections.include? conn
        process_queue
			end

      def all_connections
        (@connections + @busy_connections.values).each {|conn| yield(conn)}
      end

      private

      # Can we find a connection?
      # Can we create one?
      # Wait in the queue then
			def acquire(fiber)
        conn =  if !@connections.empty?
          @connections.shift
        elsif (@connections.length + @busy_connections.length) < @size
          @connection_proc.call
        else
					NB::Fiber.yield @queue << fiber
        end
        @busy_connections[conn.object_id] = conn
			end

      # Check if there are waiting fibers and
      # try to process them
			def process_queue
				while !@connections.empty? and !@queue.empty?
					fiber = @queue.shift
					# What is really happening here?
					# we are resuming a fiber from within
					# another, should we call transfer instead?
					fiber.resume @connections.shift
				end
			end
						
		end #FiberedConnectionPool
		
	end #Pool

end #NeverBlock
