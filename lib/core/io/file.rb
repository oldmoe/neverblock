require 'thread'
require 'reactor'

class Reactor::Base
  protected  
end

class File < IO

  @@queue = Queue.new
  @@thread_pool = []
  10.times do
    @@thread_pool << Thread.new do
      loop do
        io, method, param, fiber, reactor = *(@@queue.shift)
        begin
          result = io.__send__(method, param)
          reactor.next_tick{fiber.resume result} 
        rescue Exception => e
          puts e
          reactor.next_tick{fiber.resume e}          
        end
      end
    end
  end
  
  def sysread(length)
		return rb_sysread(length) unless NB.neverblocking?
		fiber = NB::Fiber.current
    @@queue << [self, :sysread, length, fiber, NB.reactor]
    NB::Fiber.yield
  end

  def syswrite(data)
		return rb_syswrite(data) unless NB.neverblocking?
		fiber = NB::Fiber.current
    @@queue << [self, :syswrite, data, fiber, NB.reactor]
    NB::Fiber.yield
  end  

=begin  
  def self.neverblock(method)
    self.alias_method "rb_#{method}".to_sym method
    self.define_method(method) do |*args|
      return self.send("rb_#{method}", *args) unless NB.neverblocking?
		  fiber = NB::Fiber.current
      @@queue << [self, method, args, fiber, NB.reactor]
      NB::Fiber.yield      
    end
  end
=end    
end
