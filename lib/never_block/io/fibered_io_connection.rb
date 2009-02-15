module NeverBlock
  module IO
    module FiberedIOConnection

      # Attaches the IO to an event loop and when the fiber is resumed it detaches 
			# it from the event loop
      def attach_to_reactor(mode = :read)
        if EM.reactor_running?
					connectionHandler = mode == :write ? EMWriteConnectionHandler : EMReadConnectionHandler
          @fiber = Fiber.current
          @em_connection = EM::attach(self,connectionHandler,self)
					Fiber.yield
					@em_connection.detach
	      else
          raise ::NB::NBError.new("FiberedIOConnection: EventMachine reactor not running")
        end
      end  

      # This is called whenever the socket available
      def resume
				if @fiber then
					if(@fiber['timeout_value']) then
							@fiber[:exceeded_timeout] = true if (Time.now.to_i > @fiber['timeout_value'] + @fiber['starting_time'])
					end
				  @fiber.resume
				end
      end
      
    end
    
    module EMReadConnectionHandler
      def initialize connection
        @io_connection = connection
      end
      def notify_readable
        @io_connection.resume
      end
    end

    module EMWriteConnectionHandler
      def initialize connection
        @io_connection = connection
      end
      def notify_writable
        @io_connection.resume
      end
    end
  end
end
