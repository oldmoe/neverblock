require 'mysqlplus'

module NeverBlock

  module DB
    # A modified mysql connection driver. It builds on the original pg driver.
    # This driver is able to register the socket at a certain backend (EM)
    # and then whenever the query is executed within the scope of a friendly
    # fiber. It will be done in async mode and the fiber will yield
	  class FiberedMysqlConnection < Mysql	      
                
      include FiberedDBConnection

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
        if NB.event_loop_available? && NB.neverblocking?
          raise ::NB::NBError.new("FiberedMysqlConnection: The running fiber is attached to a connection other than the current one") if (c = Fiber.current[:connection]) && c != self
          begin
            send_query sql
            Fiber.yield register_with_event_loop
            get_result
          rescue Exception => e
            if error = ['not connected', 'gone away', 'Lost connection'].detect{|msg| e.message.include? msg}
              event_loop_connection_close
              unregister_from_event_loop
              remove_unregister_from_event_loop_callbacks
              #connect
            end
            raise e
          end
        else
          super(sql)
        end
      end
      
      alias_method :exec, :query

    end #FiberedMySQLConnection

  end #DB

end #NeverBlock

NeverBlock::DB::FMysql = NeverBlock::DB::FiberedMysqlConnection
