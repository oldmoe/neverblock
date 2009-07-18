# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2009 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

require 'socket'
require 'fcntl'
require File.expand_path(File.dirname(__FILE__)+'/io')

class BasicSocket < IO

  @@getaddress_method = IPSocket.method(:getaddress)
  def self.getaddress(*args)
    @@getaddress_method.call(*args)
  end

  alias_method :recv_blocking, :recv

	def recv_neverblock(*args)
		res = ""
		begin
      old_flags = self.fcntl(Fcntl::F_GETFL, 0)
			res << recv_nonblock(*args)
      self.fcntl(Fcntl::F_SETFL, old_flags)
		rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
      self.fcntl(Fcntl::F_SETFL, old_flags)
  		NB.wait(:read, self)
  		retry
		end
		res
  end

	def recv(*args)
		if NB.neverblocking?
			recv_neverblock(*args)
    else
      recv_blocking(*args)
    end
  end

end

class Socket < BasicSocket
  
	alias_method :connect_blocking, :connect
	    
  def connect_neverblock(server_sockaddr)
    begin
      connect_nonblock(server_sockaddr)
    rescue Errno::EINPROGRESS, Errno::EINTR, Errno::EALREADY, Errno::EWOULDBLOCK
      NB.wait(:write, self)
			retry
    rescue Errno::EISCONN
      # do nothing, we are good
    end
  end
    
  def connect(server_sockaddr)
    if NB.neverblocking?
	  	connect_neverblock(server_sockaddr)
    else
      connect_blocking(server_sockaddr)
    end
  end

end

Object.send(:remove_const, :TCPSocket)

class TCPSocket < Socket
	def initialize(*args)
    super(AF_INET, SOCK_STREAM, 0)
    self.connect(Socket.sockaddr_in(*(args.reverse)))
  end
end

