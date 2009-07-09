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
		return rb_sysread(length) unless self.neverblock?
    read_neverblock(length)
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
			    return nil if sbuffer.length.zero? && length > 0
          return sbuffer if sbuffer.length <= length
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
	
	def gets(*args)
    return rb_gets(data) if self.file?
		res = ""
		args[0] = "\n\n" if args[0] == ""
		if args.length == 0
			condition = proc{|res|res.index("\n").nil?}
		elsif args.length == 1
			if args[0] == nil
				condition = proc{|res|true}		
			else
				condition = proc{|res|res.index(args[0]).nil?}
			end
		elsif args.length == 2
			count = args[1]
			if args[0] == nil
				condition = proc{|res| count = count - 1; count > -1}
			else 
				condition = proc{|res| count = count - 1; count > -1 && res.index(args[0]).nil?}
			end
		end
		begin		
			while condition.call(res)
			  res << read(1)
			end
		rescue EOFError
		end
		res
	end
	
	def readlines
    return rb_readlines if self.file?
		res = []
		begin
			loop{res << readline}
		rescue EOFError
		end
		res
	end
	
	def readchar
    return rb_readchar if self.file?
		sysread(1)[0]
	end
	
	def getc
    return rb_getc if self.file?
		begin
			res = readchar
		rescue EOFError
			res = nil
		end
	end

	def readline(sep = "\n")
    return rb_readline if self.file?
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
