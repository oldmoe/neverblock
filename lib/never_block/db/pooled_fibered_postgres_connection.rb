module NeverBlock
  module DB
    # A pooled postgres connection class. 
    # This class represents a proxy interface
    # to a connection pool of fibered postgresql
    # connections.
    class PooledFiberedPostgresConnection

      # Requires a hash or an array with connection parameters
      # and a pool size (defaults to 4)
      def initialize(conn_params, size=4)
        @pool = NB::Pool::FiberedConnectionPool.new(:size=>size, :eager=>true) do
          conn = NB::DB::FPGconn.new(*conn_params) if conn_params.is_a? Array
          conn = NB::DB::FPGconn.new(conn_params) if conn_params.is_a? Hash          
	        conn.register_with_event_loop(:em)
          conn          
        end
      end
      
      # A proxy for the connection's exec method
      # quries the pool to get a connection first
      def exec(query)
        @pool.hold do |conn|
          conn.exec(query)
        end
      end
      
      # This method must be called for transactions to work correctly.
      # One cannot just send "begin" as you never know which connection
      # will be available next. This method ensures you get the same connection
      # while in a transaction.
      def begin_db_transaction
        @pool.hold(true) do |conn|
          conn.exec("begin")
        end
      end
      
      # see =begin_db_transaction
      def rollback_db_transaction
        @pool.hold do |conn|
          conn.exec("rollback")
          @pool.release(Fiber.current,conn)
        end
      end
      
      # see =begin_db_transaction
      def commit_db_transaction
        @pool.hold do |conn|
          conn.exec("commit")
          @pool.release(Fiber.current,conn)
        end
      end

      #close all connections and remove them from the event loop
      def close
        @pool.all_connections do |conn|
          conn.unregister_from_event_loop
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

NB::DB::PFPGconn = NeverBlock::DB::FiberedPostgresConnection

