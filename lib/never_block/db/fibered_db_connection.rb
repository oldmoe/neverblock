module NeverBlock
  module DB
    module FiberedDBConnection

      # Attaches the connection socket to an event loop and adds a callback
      # to the fiber's callbacks that unregisters the connection from event loop
      # Raises NB::NBError
      def register_with_event_loop
        #puts ">>>>>register_with_event_loop"
        if EM.reactor_running?
          @fiber = Fiber.current
          #puts ">>>>>register_with_event_loop fiber #{@fiber.inspect}"
          # When there's no previous em_connection
          unless @fiber[em_connection_with_pool_key]
            @fiber[em_connection_with_pool_key] = EM::attach(socket,EMConnectionHandler,self)
            @fiber[:callbacks] << self.method(:unregister_from_event_loop)
          end
        else
          raise ::NB::NBError.new("FiberedDBConnection: EventMachine reactor not running")
        end
      end  

      # Unattaches the connection socket from the event loop
      def unregister_from_event_loop
        #puts ">>>>>unregister_from_event_loop #{self.inspect} #{@fiber.inspect}"
        if em_c = @fiber[em_connection_with_pool_key]
          em_c.detach
          @fiber[em_connection_with_pool_key] = nil
          true
        else
          false
        end
      end

      # Removes the unregister_from_event_loop callback from the fiber's
      # callbacks. It should be used when errors occur in an already registered
      # connection
      def remove_unregister_from_event_loop_callbacks
        @fiber[:callbacks].delete self.method(:unregister_from_event_loop)
      end

      # Closes the connection using event loop
      def event_loop_connection_close
        @fiber[em_connection_with_pool_key].close_connection if @fiber[em_connection_with_pool_key]
      end
           
      # The callback, this is called whenever
      # there is data available at the socket
      def resume_command
        @fiber.resume if @fiber
      end
      
      private
      def em_connection_with_pool_key
        "em_#{@fiber[:current_pool_key]}".intern
      end
    end
    
    module EMConnectionHandler
      def initialize connection
        @db_connection = connection
      end
      def notify_readable
        @db_connection.resume_command
      end
    end
  end
end
