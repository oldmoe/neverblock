require 'mysqlplus'

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
	  class FiberedMysqlConnection < Mysql	      
      # needed to access the sockect by the event loop
      attr_reader :fd, :io

      # Initializes file desciptor and IO object
      # return the connection object itself
      def init_descriptor
        @fd = socket
        @io = IO.new(socket)
        self
      end

      # Initializes the file descriptor and IO object for a given connection
      # returns instance
      def self.init_descriptor(instance)
        instance.init_descriptor
      end

      def initialize(*args)
        super(*args)
        init_descriptor
      end

      # Creates a new mysql connection, sets it
      # to nonblocking and wraps the descriptor in an IO
      # object.
	    def self.real_connect(*args)
        init_descriptor(super(*args))
      end

      def real_connect(*args)
        super(*args).init_descriptor
      end

      def self.connect(*args)
        init_descriptor(super(*args))
      end

      def connect(*args)
        super(*args).init_descriptor
      end
        
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
          # TODO handle the case of losing the connection
          # reconnect if e.message.include? "not connected"
          raise e
        end		
      end

      # reset the connection
      # and reattach to the
      # event loop
      # def reconnect
      #  unregister_from_event_loop
      #  super
      #  init_descriptor
      #  register_with_event_loop(@loop)
      # end
      
      # Attaches the connection socket to an event loop.
      # Currently only supports EM, but Rev support will be
      # completed soon.
      def register_with_event_loop(loop)
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
          loop.attach(RevConnectionHandler.new(socket))
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
      
    end #FiberedPostgresConnection 
    
    # A connection handler for EM
    # More to follow.
    module EMConnectionHandler
      def initialize connection
        @connection = connection
      end
      def notify_readable
        @connection.resume_command
      end
    end

    end #DB

end #NeverBlock

NeverBlock::DB::FMysql = NeverBlock::DB::FiberedMysqlConnection
