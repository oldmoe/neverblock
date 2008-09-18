require 'pg'

module NeverBlock

  module DB
  
    # A modified postgres connection driver
    # builds on the original pg driver.
    # This driver is able to register the socket
    # at a certain backend (EM or Rev)
    # and then whenever the query is executed
    # within the scope of a friendly fiber
    # it will be done in async mode and the fiber
    # will yield
	  class FiberedPostgresConnection < PGconn	      
              
      include FiberedDBConnection

      # Assuming the use of NeverBlock fiber extensions and that the exec is run in
      # the context of a fiber. One that have the value :neverblock set to true.
      # All neverblock IO classes check this value, setting it to false will force
      # the execution in a blocking way.
      def exec(sql)
        begin
          if Fiber.respond_to? :current and Fiber.current[:neverblock]		      
            send_query sql
            @fiber = Fiber.current		      
            Fiber.yield 
            while is_busy
              consume_input
              Fiber.yield if is_busy
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
        rescue Exception => e
          reset if e.message.include? "not connected"
          raise e
        end		
      end

      alias :query :exec

      # reset the connection
      # and reattach to the
      # event loop
      def reset
        unregister_from_event_loop
        super
        register_with_event_loop(@loop)    
      end
            
    end #FiberedPostgresConnection 

    end #DB

end #NeverBlock

NeverBlock::DB::FPGconn = NeverBlock::DB::FiberedPostgresConnection
