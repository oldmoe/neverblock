require File.expand_path(File.dirname(__FILE__)+'/pool')

module NeverBlock

  module DB
    # a proxy for pooled fibered connections
    class Connection
      # Requires a block with connection parameters
      # and a pool size (defaults to 4)
      def initialize(size=4, &block)
        @pool = NB::DB::Pool.new(:size=>size, :eager=>true) do
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

      # Replaces the current connection with a brand new one
      def replace_acquired_connection
        @pool.replace_acquired_connection
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

      protected
      
      # are we in a transaction?
      # if no then just hold a connection and run the block
      # else get a connection, pass it to the block
      # and move away     
      def hold_connection
      
      end      
      
    end
  end
end
