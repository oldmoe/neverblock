module NeverBlock
  module DB
    # a proxy for pooled fibered connections
    class PooledDBConnection
      # Requires a block with connection parameters
      # and a pool size (defaults to 4)
      def initialize(size=4, &block)
        @pool = NB::Pool::FiberedConnectionPool.new(:size=>size, :eager=>true) do
          yield
        end
      end
            
      # A proxy for the connection's query method
      # quries the pool to get a connection first
      def query(query)
        @pool.hold do |conn|
          conn.query(query)
        end
      end

      alias :exec :query
      
      # This method must be called for transactions to work correctly.
      # One cannot just send "begin" as you never know which connection
      # will be available next. This method ensures you get the same connection
      # while in a transaction.
      def begin_db_transaction
        @pool.hold(true) do |conn|
          conn.query("begin")
        end
      end
      
      # see =begin_db_transaction
      def rollback_db_transaction
        @pool.hold do |conn|
          conn.query("rollback")
          @pool.release(Fiber.current,conn)
        end
      end
      
      # see =begin_db_transaction
      def commit_db_transaction
        @pool.hold do |conn|
          conn.query("commit")
          @pool.release(Fiber.current,conn)
        end
      end

      #close all connections and remove them from the event loop
      def close
        @pool.all_connections do |conn|
          conn.close
        end
      end
      
      # Pass unknown methods to the connection
      def method_missing(method, *args)
        @pool.hold do |conn|
          conn.send(method, *args)
        end        
      end

      # Pass method queries to the connection
      def respond_to?(method)
        @pool.hold do |conn|
          conn.respond_to?(method)
        end        
      end      
    end
  end
end
