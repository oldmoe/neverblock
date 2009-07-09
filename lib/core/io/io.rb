require 'fcntl'

# This is an extention to the Ruby IO class that makes it compatable with
#	NeverBlocks event loop to avoid blocking IO calls. That's done by delegating
#	all the reading methods to read_nonblock and all the writting methods to
#	write_nonblock. 

class IO

	NB_BUFFER_LENGTH = 128*1024
	
  alias_method :rb_sysread,   :sysread
  alias_method :rb_syswrite,  :syswrite
  alias_method :rb_read,      :read
  alias_method :rb_write,     :write
  alias_method :rb_gets,      :gets
  alias_method :rb_getc,      :getc
  alias_method :rb_readchar,  :readchar
  alias_method :rb_readline,  :readline
  alias_method :rb_readlines, :readlines
  alias_method :rb_print,     :print
  
	#	This method is the delegation method which reads using read_nonblock()
	#	and registers the IO call with event loop if the call blocks. The value
	# @immediate_result is used to get the value that method got before it was blocked.

  def read_neverblock(*args)
		res = ""
		begin
      old_flags = get_flags			
			res << read_nonblock(*args)
      set_flags(old_flags)
		rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
      set_flags(old_flags)
  		NB.wait(:read, self)
  		retry
		end
		res
  end

	#	The is the main reading method that all other methods use.
	#	If the mode is set to neverblock it uses the delegation method.
	#	Otherwise it uses the original ruby read method.

  def sysread(length)
    self.neverblock? ? read_neverblock(length) : rb_sysread(length)
  end
  
  def read(length=nil, sbuffer=nil)
    return rb_read(length, sbuffer) if self.file?
    return '' if length == 0
    if sbuffer.nil?
      sbuffer = '' 
    else
     sbuffer = sbuffer.to_str
     sbuffer.delete!(sbuffer)
    end    
    if length.nil?
      # we need to read till end of stream
      loop do
        begin 
          sbuffer << sysread(NB_BUFFER_LENGTH)
        rescue EOFError
      	  break
        end
      end
      return sbuffer 
    else # length != nil
      if self.buffer.length >= length
        sbuffer << self.buffer.slice!(0, length)
        return sbuffer
      elsif self.buffer.length > 0
        sbuffer << self.buffer
      end
      self.buffer = ''
      remaining_length = length - sbuffer.length
	    while sbuffer.length < length && remaining_length > 0 
		    begin 
			    sbuffer << sysread(NB_BUFFER_LENGTH < remaining_length ? remaining_length : NB_BUFFER_LENGTH)
          remaining_length = remaining_length - sbuffer.length   
		    rescue EOFError
          break
		    end #begin
	    end	#while	  
    end #if length 
    return nil if sbuffer.length.zero? && length > 0
    return sbuffer if sbuffer.length <= length
		self.buffer << sbuffer.slice!(length, sbuffer.length-1)
    return sbuffer
  end

  def write_neverblock(data)
		written = 0
		begin
      old_flags = get_flags			
			written = written + write_nonblock(data[written,data.length])
      set_flags(old_flags)
			raise Errno::EAGAIN if written < data.length
		rescue Errno::EWOULDBLOCK, Errno::EAGAIN, Errno::EINTR
      set_flags(old_flags)
  		NB.wait(:write, self)
			retry
	  end
		written
  end

	def syswrite(*args)	
		return rb_syswrite(*args) unless self.neverblock?
			write_neverblock(*args)
	end
  
	def write(data)
    return 0 if data.to_s.empty?
    return rb_write(data) if self.file?
		syswrite(data)
	end 
	
	def gets(sep=$/)
    return rb_gets(sep) if self.file?
		res = ""
		sep = "\n\n" if sep == ""
		sep = $/ if sep.nil?
		while res.index(sep).nil?
		  break if (c = read(1)).nil
		  res << c
		end
		$_ = res
		res
	end
	
	def readlines(sep=$/)
    return rb_readlines(sep) if self.file?
		res = []
		begin
			loop{res << readline(sep)}
		rescue EOFError
		end
		res
	end
	
	def readchar
    return rb_readchar if self.file?
		ch = read(1)
		raise EOFError if ch.nil?
		ch
	end
	
	def getc
    return rb_getc if self.file?
		begin
			res = readchar
		rescue EOFError
			res = nil
		end
	end

	def readline(sep = $/)
    return rb_readline(sep) if self.file?
		res = gets(sep)
		raise EOFError if res == nil
		res
	end
	
	def print(*args)
    return rb_print if self.file?
		args.each{|element|syswrite(element)}
	end

	protected

  def get_flags
    self.fcntl(Fcntl::F_GETFL, 0)
  end

  def set_flags(flags)
    self.fcntl(Fcntl::F_SETFL, flags)
  end

	def buffer
	 @buffer ||= ""
	end		

	def buffer=(value)
	 @buffer = value
	end		
	
	def file?
	  @file ||= self.stat.file?
	end

  def neverblock?
    !file? && NB.neverblocking?
	end	

end
