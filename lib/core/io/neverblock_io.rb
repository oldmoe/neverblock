require 'fcntl'

# This is an extention to the Ruby IO class that makes it compatable with
#	NeverBlocks event loop to avoid blocking IO calls. That's done by delegating
#	all the reading methods to read_nonblock and all the writting methods to
#	write_nonblock. 

class IO

	NB_BUFFER_LENGTH = 128*1024
  alias_method :read_blocking, :sysread
  alias_method :write_blocking, :syswrite

  def get_flags
    self.fcntl(Fcntl::F_GETFL, 0)
  end

  def set_flags(flags)
    self.fcntl(Fcntl::F_SETFL, flags)
  end

	def buffer
	 @buffer ||= ""
	end		

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

  def sysread(*args)
		if NB.neverblocking?
			res = read_neverblock(*args)
    else
      res = read_blocking(*args)
    end
		res
  end
  
  def read(length=nil, sbuffer=nil)
    return '' if length == 0
    if length.nil?
      sbuffer.nil? ? sbuffer = '' : sbuffer.delete!(sbuffer)
      # we need to read till end of stream
	    eof=false
      while !eof 
        begin 
          sbuffer << sysread(NB_BUFFER_LENGTH)
          eof = true if sbuffer.length == 0 
        rescue EOFError
      	  eof = true
        end
      end 
      if sbuffer.length > 0
        return sbuffer
      else
        return length.nil? ? '' : nil
      end
    else
    eof = false
    if sbuffer.nil?
      sbuffer = '' 
    else
     sbuffer = sbuffer.to_str
     sbuffer.delete!(sbuffer)
    end
    remaining_length = length
	  while sbuffer.length < length && !eof && remaining_length > 0 
		  begin 
			  sbuffer << sysread(NB_BUFFER_LENGTH > remaining_length ? remaining_length : NB_BUFFER_LENGTH)
        remaining_length = remaining_length - NB_BUFFER_LENGTH   
		  rescue EOFError
        eof=true
			  return nil if sbuffer.length.zero? && length > 0
		  end #begin
	  end	#while	  
    end #if length 
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
#		if NB.neverblocking?
			write_neverblock(*args)
#		else
#			write_blocking(*args)
#		end
	end
  
	def write(*args)
		syswrite(*args)
	end 
	
	def gets(*args)
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
		res = []
		begin
			loop{res << readline}
		rescue EOFError
		end
		res
	end
	
	def readchar
		sysread(1)[0]
	end
	
	def getc
		begin
			res = readchar
		rescue EOFError
			res = nil
		end
	end

	def readline(sep = "\n")
		res = gets(sep)
		raise EOFError if res == nil
		res
	end

	def readbytes(*args)
		sysread(*args)
	end
	
	def print(*args)
		args.each{|element|syswrite(element)}
	end
end
