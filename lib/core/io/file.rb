require 'thread'
require 'reactor'

class Reactor::Base
  protected  
end

class File < IO

  @@queue = Queue.new
  @@thread_pool = []
  20.times do
    @@thread_pool << Thread.new do
      loop do
        io, method, params, fiber, reactor = *(@@queue.shift)
        begin
          result = io.__send__(method, *params)
          reactor.next_tick{fiber.resume result} if fiber.alive? 
        rescue Exception => e
          reactor.next_tick{fiber.resume e} if fiber.alive?          
        end
      end
    end
  end
  
  def self.neverblock(*methods)
    methods.each do |method|  
      class_eval %{
        def #{method}(args)
          return rb_#{method}(*args) unless NB.neverblocking?
          @@queue << [self, :#{method}, args, NB::Fiber.current, NB.reactor]
          NB::Fiber.yield      
        end
      }
    end
  end
  
  neverblock :syswrite, :sysread, :write, :read, :readline, 
             :readlines, :readchar, :gets, :getc, :print
  
end
