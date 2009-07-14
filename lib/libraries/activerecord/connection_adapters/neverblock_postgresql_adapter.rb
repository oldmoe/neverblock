# Require original mysql adapter as we'll just extend it
require 'active_record/connection_adapters/postgresql_adapter'

class ActiveRecord::ConnectionAdapters::NeverBlockPostgreSQLAdapter < ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      # Returns 'FiberedPostgreSQL' as adapter name for identification purposes.
      def adapter_name
        'NeverBlockPostgreSQL'
      end

      def connect
        @connection = ::NB::DB::FiberedPostgresConnection.connect(*@connection_parameters[1..(@connection_parameters.length-1)])
      end

      # Close then reopen the connection.
      def reconnect!
        disconnect!
        connect
      end

end

class ActiveRecord::ConnectionAdapters::ConnectionPool
  def current_connection_id #:nodoc:
    NB::Fiber.current.object_id
  end

  def checkout
    # Checkout an available connection
    loop do
      conn = if @checked_out.size < @connections.size
               checkout_existing_connection
             elsif @connections.size < @size
               checkout_new_connection
             end
      return conn if conn
      # No connections available; wait for one
      @waiting ||= []
      NB::Fiber.yield @waiting << NB::Fiber.current
    end
  end

  def checkin(conn)
    conn.run_callbacks :checkin
    @checked_out.delete conn
    if @waiting && @waiting.size > 0
      @waiting.shift.resume
    end
  end
end

class ActiveRecord::Base
  # Establishes a connection to the database that's used by all Active Record objects
  def self.neverblock_postgresql_connection(config) # :nodoc:
    config = config.symbolize_keys
    host     = config[:host]
    port     = config[:port] || 5432
    username = config[:username].to_s
    password = config[:password].to_s
    size     = config[:connections] || 4

    if config.has_key?(:database)
      database = config[:database]
    else
      raise ArgumentError, "No database specified. Missing argument: database."
    end

    # The postgres drivers don't allow the creation of an unconnected PGconn object,
    # so just pass a nil connection object for the time being.
    ::ActiveRecord::ConnectionAdapters::NeverBlockPostgreSQLAdapter.new(nil, logger, [size, host, port, nil, nil, database, username, password], config)
  end  
end
