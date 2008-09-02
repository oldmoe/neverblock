module NeverBlock
  module DB
    # A pooled postgres connection class. 
    # This class represents a proxy interface
    # to a connection pool of fibered postgresql
    # connections.
    class PooledFiberedMysqlConnection

      # Requires a hash or an array with connection parameters
      # and a pool size (defaults to 4)
      def initialize(size=4, &block)
        @pool = NB::Pool::FiberedConnectionPool.new(:size=>size, :eager=>true) do
          yield
        end
      end
      
      # A proxy for the connection's exec method
      # quries the pool to get a connection first
      def exec(query)
        @pool.hold do |conn|
          conn.query(query)
        end
      end
      
      alias :query :exec
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

NeverBlock::DB::PFMysql = NeverBlock::DB::PooledFiberedMysqlConnection
