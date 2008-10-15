module NeverBlock
  module DB
    module FiberedDBConnection
      # Attaches the connection socket to an event loop.
      # Currently only supports EM, but Rev support will be
      # completed soon.
      def register_with_event_loop(loop)
        @fd = socket
        @io = IO.new(socket)
        if loop == :em
          if EM.reactor_running?
            @em_connection = EM::attach(@io,EMConnectionHandler,self)
          else
            raise "EventMachine reactor not running"
          end
        else
          raise "Could not register with the event loop"
        end
        @loop = loop
      end  

      # Unattaches the connection socket from the event loop
      def unregister_from_event_loop
        if @loop == :em
          if @em_connection
            @em_connection.detach
            @em_connection = nil
            true
          else
            false
          end
        else
          raise NotImplementedError.new("unregister_from_event_loop not implemented for #{@loop}")
        end
      end
           
      # The callback, this is called whenever
      # there is data available at the socket
      def resume_command
        #protection against being called several times
        if @fiber
          f = @fiber
          @fiber = nil
          f.resume
        else
          unregister_from_event_loop
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
