require 'mysqlplus'

module NeverBlock

  module DB
    # A modified mysql connection driver. It builds on the original pg driver.
    # This driver is able to register the socket at a certain backend (EM)
    # and then whenever the query is executed within the scope of a friendly
    # fiber. It will be done in async mode and the fiber will yield
	  class FiberedMysqlConnection < Mysql
                
      # Initializes the connection and remembers the connection params
      def initialize(*args)
        @connection_params = args
        super(*@connection_params)
      end

      # Does a normal real_connect if arguments are passed. If no arguments are
      # passed it uses the ones it remembers
      def real_connect(*args)
        @connection_params = args unless args.empty?
        super(*@connection_params)
      end

      alias_method :connect, :real_connect

      # Assuming the use of NeverBlock fiber extensions and that the exec is run in
      # the context of a fiber. One that have the value :neverblock set to true.
      # All neverblock IO classes check this value, setting it to false will force
      # the execution in a blocking way.
      def query(sql)
        if NB.neverblocking? && NB.reactor.running?
          send_query sql
          NB.wait(:read, IO.new(socket))
          get_result
        else
          super(sql)
        end
      end
      
      alias_method :exec, :query

    end #FiberedMySQLConnection

  end #DB

end #NeverBlock

NeverBlock::DB::FMysql = NeverBlock::DB::FiberedMysqlConnection
