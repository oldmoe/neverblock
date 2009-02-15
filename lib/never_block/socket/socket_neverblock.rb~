require 'rubygems'
require File.expand_path(File.dirname(__FILE__) + "/fix_sockets")

class Socket
  
	alias_method :connect_blocking, :connect
	    
  def connect_neverblock(server_sockaddr)
    begin
      connect_nonblock(server_sockaddr)
    rescue Errno::EINPROGRESS, Errno::EINTR, Errno::EALREADY, Errno::EWOULDBLOCK
			attach_to_reactor(:write)
			retry
    rescue Errno::EISCONN
    end
  end
    
  def connect(server_sockaddr)
    if Fiber.current[:neverblock]
	  	connect_neverblock(server_sockaddr)
    else
      connect_blocking(server_sockaddr)
    end
  end
end
