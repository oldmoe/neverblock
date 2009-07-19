require File.expand_path(File.dirname(__FILE__)+'/../lib/neverblock/io/db/drivers/postgres')
require File.expand_path(File.dirname(__FILE__)+'/../lib/neverblock/io/db/connection')

module NeverBlock

  module DB
  
    # A modified postgres connection driver
    # builds on the original pg driver.
    # This driver is able to register the socket
    # at a certain backend (Reacotr)
    # and then whenever the query is executed
    # within the scope of a friendly fiber (NB::Fiber)
    # it will be done in async mode and the fiber
    # will yield
	  class Postgres < PGconn	                    

      # Assuming the use of NeverBlock fiber extensions and that the exec is run in
      # the context of a fiber. One that have the value :neverblock set to true.
      # All neverblock IO classes check this value, setting it to false will force
      # the execution in a blocking way.
      def exec(sql)
        # TODO Still not "killing the query process"-proof
        # In some cases, the query is simply sent but the fiber never yields
        if NB.neverblocking? && NB.reactor.running?
          send_query sql
          while is_busy
            NB.wait(:read, IO.new(socket))
            consume_input
          end
          res, data = 0, []
          while res != nil
            res = self.get_result
            data << res unless res.nil?
          end
          data.last
        else
          super(sql)
        end
      end

      alias_method :query, :exec
            
    end #Postgres 

    class PooledPostgres < ::NeverBlock::DB::Connection

      def initialize(*args)
        options = {}
        if args && (options = args.last).is_a? Hash
          size = options[:size] || 4
          eager = options[:eager] || true
          args.pop
        end
        @pool = NB::DB::Pool.new(:size=>size, :eager=>eager) do
          Postgres.new(*args)
        end
      end

    end #PooledMySQL
  end #DB

end #NeverBlock
