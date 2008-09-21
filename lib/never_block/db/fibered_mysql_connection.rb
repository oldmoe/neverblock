require 'mysqlplus'

module NeverBlock

  module DB
    # A modified mysql connection driver
    # builds on the original pg driver.
    # This driver is able to register the socket
    # at a certain backend (EM or Rev)
    # and then whenever the query is executed
    # within the scope of a friendly fiber
    # it will be done in async mode and the fiber
    # will yield
	  class FiberedMysqlConnection < Mysql	      
                
      include FiberedDBConnection
        
      # Assuming the use of NeverBlock fiber extensions and that the exec is run in
      # the context of a fiber. One that have the value :neverblock set to true.
      # All neverblock IO classes check this value, setting it to false will force
      # the execution in a blocking way.
      def query(sql)
        begin
          if Fiber.respond_to? :current and Fiber.current[:neverblock]		      
            send_query sql
            @fiber = Fiber.current		      
            Fiber.yield
            get_result 
          else		      
            super(sql)
          end
        rescue Exception => e
          if error = ['not connected', 'gone away', 'Lost connection'].detect{|msg| e.message.include? msg}
            stop
            connect
          end
          raise e
        end		
      end

      alias :exec :query
      
      # stop the connection
      # and deattach from the
      # event loop      
      def stop
        unregister_from_event_loop
        super
      end

      # The callback, this is called whenever
      # there is data available at the socket
      def resume_command
        @fiber.resume
      end
      
      # reconnect 
      # and attach to the
      # event loop      
      def connect
        super
        register_with_event_loop(@loop)    
      end
            
    end #FiberedMySQLConnection 

  end #DB

end #NeverBlock

NeverBlock::DB::FMysql = NeverBlock::DB::FiberedMysqlConnection
