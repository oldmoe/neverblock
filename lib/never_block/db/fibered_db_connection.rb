module NeverBlock
  module DB
    module FiberedDBConnection

      # Attaches the connection socket to an event loop.
      # Currently only supports EM, but Rev support will be
      # completed soon.
      def register_with_event_loop
        if EM.reactor_running?
          @em_connection = EM::attach(socket,EMConnectionHandler,self)
        else
          raise "EventMachine reactor not running"
        end
      end  

      # Unattaches the connection socket from the event loop
      def unregister_from_event_loop
        if @em_connection
          @em_connection.detach
          @em_connection = nil
          true
        else
          false
        end
      end

      # Closes the connection using event loop
      def event_loop_connection_close
        @em_connection.close_connection if @em_connection
      end
           
      # The callback, this is called whenever
      # there is data available at the socket
      def resume_command
        #protection against being called several times
        if @fiber
          f = @fiber
          @fiber = nil
          f.resume
        end
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
