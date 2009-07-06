require 'active_record/connection_adapters/postgresql_adapter'
require 'neverblock-pg'
require 'never_block/frameworks/activerecord'


class ActiveRecord::ConnectionAdapters::NeverBlockPostgreSQLAdapter < ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      # Returns 'FiberedPostgreSQL' as adapter name for identification purposes.
      def adapter_name
        'NeverBlockPostgreSQL'
      end

      # Executes an INSERT query and returns the new record's ID, this wont
      # work on earlier versions of PostgreSQL but they don't suppor the async
      # interface anyway
#      def insert(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil)
#        @connection.exec(sql << " returning id ") 
#      end

      def connect
        @connection = ::NB::DB::PooledDBConnection.new(@connection_parameters[0]) do
          conn = ::NB::DB::FiberedPostgresConnection.connect(*@connection_parameters[1..(@connection_parameters.length-1)])
=begin
          ::NB::DB::FiberedPostgresConnection.translate_results = false if ::NB::DB::FiberedPostgresConnection.respond_to?(:translate_results=)
          # Ignore async_exec and async_query when using postgres-pr.
          @async = @config[:allow_concurrency] && @connection.respond_to?(:async_exec)
          # Use escape string syntax if available. We cannot do this lazily when encountering
          # the first string, because that could then break any transactions in progress.
          # See: http://www.postgresql.org/docs/current/static/runtime-config-compatible.html
          # If PostgreSQL doesn't know the standard_conforming_strings parameter then it doesn't
          # support escape string syntax. Don't override the inherited quoted_string_prefix.
          NB.neverblock(false) do
            if supports_standard_conforming_strings?
              self.class.instance_eval do
                define_method(:quoted_string_prefix) { 'E' }
              end
            end
            # Money type has a fixed precision of 10 in PostgreSQL 8.2 and below, and as of
            # PostgreSQL 8.3 it has a fixed precision of 19. PostgreSQLColumn.extract_precision
            # should know about this but can't detect it there, so deal with it here.
            money_precision = (postgresql_version >= 80300) ? 19 : 10
            ::ActiveRecord::ConnectionAdapters::PostgreSQLColumn.module_eval(<<-end_eval)
              def extract_precision(sql_type)
                if sql_type =~ /^money$/
                  #{money_precision}
                else
                  super
                end
              end
            end_eval
            #configure_connection
          end
	  conn
=end
        end
      end

      # Close then reopen the connection.
      def reconnect!
        disconnect!
        connect
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
