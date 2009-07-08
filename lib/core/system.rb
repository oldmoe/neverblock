$:.unshift File.expand_path(File.dirname(__FILE__))
require 'concurrent/fiber'
require 'timeout'

module Kernel
  alias_method :blocking_sleep, :sleep
  def sleep(time=nil)
    if NB.neverblocking?
      NB::Fiber.yield if time.nil?
      return if time <= 0
      fiber = NB::Fiber.current
      NB.reactor.add_timer(time){fiber.resume}
      NB::Fiber.yield
    else
      blocking_sleep(time)
    end
  end

  def system(cmd, *args)
    begin
      backticks(cmd, *args)
      result = $?.exitstatus
      return true if result.zero?
      return nil if result == 127
      return false
    rescue Errno::ENOENT => e
      return nil
    end
  end

  def backticks(cmd, *args)
    myargs = "#{cmd} "
    myargs << args.join(' ') if args
    res = ''    
    IO.popen(myargs) do |f|
      res << f.read
    end
    res
  end
  
end

module Timeout

  def timeout(time, klass=Timeout::Error)
    if time.nil? || time <= 0
      yield
    else
      fiber = NB::Fiber.current
      timer = NB.reactor.add_timer(time) do 
        fiber[:timeouts].last.each do |event|
          if event.is_a? Reactor::Timer
            event.cancel
          else
            NB.reactor.detach(event[0], event[1])
          end
        end
        fiber.resume(klass.new)
      end
      fiber[:timeouts] = [] unless fiber[:timeout] 
      fiber[:timeouts] << []
      begin
        yield
      rescue Exception => e
        raise e        
      ensure
        timer.cancel  
        fiber[:timeouts].pop
      end
    end
  end
  
  module_function :timeout  

end
