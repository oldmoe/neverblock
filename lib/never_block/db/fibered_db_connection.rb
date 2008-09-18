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
          unless EM.respond_to?(:attach)
            puts "invalide EM version, please download the modified gem from: (http://github.com/riham/eventmachine)"
            exit
          end
          if EM.reactor_running?
            @em_connection = EM::attach(@io,EMConnectionHandler,self)
          else
            raise "REACTOR NOT RUNNING YA ZALAMA"
          end 
        elsif loop.class.name == "REV::Loop"
          loop.attach(RevConnectionHandler.new(@fd))
        else
          raise "could not register with the event loop"
        end
        @loop = loop
      end  

      # Unattaches the connection socket from the event loop
      def unregister_from_event_loop
        if @loop == :em
          @em_connection.unattach(false)
        else
          raise NotImplementedError.new("unregister_from_event_loop not implemented for #{@loop}")
        end
      end
           
      # The callback, this is called whenever
      # there is data available at the socket
      def resume_command
        @fiber.resume
      end
      
    end
    
    module EMConnectionHandler
      def initialize connection
        @connection = connection
      end
      def notify_readable
        @connection.resume_command
      end
    end
  end
end
