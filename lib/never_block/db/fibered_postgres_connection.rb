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
        # TODO Still not "killing the query process"-proof
        # In some cases, the query is simply sent but the fiber never yields
        if NB.event_loop_available? && NB.neverblocking?
          begin
            send_query sql
            @fiber = Fiber.current
            Fiber.yield register_with_event_loop
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
          rescue Exception => e
            if error = ['not connected', 'gone away', 'Lost connection','no connection'].detect{|msg| e.message.include? msg}
              event_loop_connection_close
              unregister_from_event_loop
              remove_unregister_from_event_loop_callbacks
            end
            raise e
          end
        else
          super(sql)
        end
      end

      alias_method :query, :exec
            
    end #FiberedPostgresConnection 

    end #DB

end #NeverBlock

NeverBlock::DB::FPGconn = NeverBlock::DB::FiberedPostgresConnection
