require 'timeout'
require File.expand_path(File.dirname(__FILE__)+'/../../../neverblock')

module Timeout

  alias_method :rb_timeout, :timeout
  
  def timeout(time, klass=Timeout::Error)
    return rb_timeout(time, klass) unless NB.neverblocking?
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
      (fiber[:timeouts] ||= []) << []
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

NB.reactor.on_add_timer do |timer|
  timeouts = NB::Fiber.current[:timeouts]
  unless timeouts.nil? || timeouts.empty?
    timeouts.last << timer
  end
end

NB.reactor.on_attach do |mode, io|
  timeouts = NB::Fiber.current[:timeouts]
  unless timeouts.nil? || timeouts.empty?
    timeouts.last << [mode, io]
  end
end

NB.reactor.on_detach do |mode, io|
  timeouts = NB::Fiber.current[:timeouts]
  unless timeouts.nil? || timeouts.empty?
    timeouts.delete_if{|to|to.is_a? Array && to[0] == mode && to[1] == io}
  end
end

