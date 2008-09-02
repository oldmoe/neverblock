require 'activesupport'
require 'never_block/frameworks/activerecord'
require 'active_record/connection_adapters/mysql_adapter'
require 'neverblock-mysql'

class ActiveRecord::ConnectionAdapters::NeverBlockMysqlAdapter < ActiveRecord::ConnectionAdapters::MysqlAdapter

  # Returns 'NeverBlockMySQL' as adapter name for identification purposes
  def adapter_name
    'NeverBlockMySQL'
  end

  def insert_sql(sql, name = nil, pk = nil, id_value = nil, sequence_name = nil) #:nodoc:
    begin_db_transaction
    super sql, name
    id_value || @connection.insert_id
    commit_db_transaction
  end

  def update_sql(sql, name = nil) #:nodoc:
    begin_db_transaction
    super
    @connection.affected_rows
    commit_db_transaction
  end

  def begin_db_transaction
    @connection.begin_db_transaction
  end
  
  def commit_db_transaction
    @connection.commit_db_transaction
  end

  def rollback_db_transaction
    @connection.rollback_db_transaction
  end

  def connect
    @connection = ::NB::DB::PooledFiberedMysqlConnection.new(@connection_options.shift) do
      conn = ::NB::DB::FMysql.init
      encoding = @config[:encoding]
      if encoding
        conn.options(::NB::DB::FMysql::SET_CHARSET_NAME, encoding) rescue nil
      end
      conn.ssl_set(@config[:sslkey], @config[:sslcert], @config[:sslca], @config[:sslcapath], @config[:sslcipher]) if @config[:sslkey]
      conn.real_connect(*@connection_options)
      conn.query("SET NAMES '#{encoding}'") if encoding
      # By default, MySQL 'where id is null' selects the last inserted id.
      # Turn this off. http://dev.rubyonrails.org/ticket/6778
      # conn.query("SET SQL_AUTO_IS_NULL=0")
      conn.register_with_event_loop(:em)
      conn          
    end
  end  

end

class ActiveRecord::Base
  # Establishes a connection to the database that's used by all Active Record objects
  def self.neverblock_mysql_connection(config) # :nodoc:
    config = config.symbolize_keys
    host     = config[:host]
    port     = config[:port]
    socket   = config[:socket]
    username = config[:username] ? config[:username].to_s : 'root'
    password = config[:password].to_s
    size     = config[:connections] || 4

    if config.has_key?(:database)
      database = config[:database]
    else
      raise ArgumentError, "No database specified. Missing argument: database."
    end
    MysqlCompat.define_all_hashes_method!
    ::ActiveRecord::ConnectionAdapters::NeverBlockMysqlAdapter.new(nil, logger, [size.to_i, host, username, password, database, port, socket, nil], config)
  end  
end
