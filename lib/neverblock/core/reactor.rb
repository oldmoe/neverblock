require 'reactor'
require 'thread'
require File.expand_path(File.dirname(__FILE__)+'/fiber')

module NeverBlock

  @@reactors = {}

  @@queue = Queue.new

  @@thread_pool = []

  20.times do
    @@thread_pool << Thread.new do
      loop do
        io, method, params, fiber, reactor = *(@@queue.shift)
        begin
          reactor.next_tick{fiber.resume(io.__send__(method, *params))} if fiber.alive? 
        rescue Exception => e
          reactor.next_tick{fiber.resume(e)} if fiber.alive?          
        end
      end
    end
  end

  def self.reactor
    @@reactors[Thread.current.object_id] ||= ::Reactor::Base.new
  end

  def self.wait(mode, io)
    fiber = NB::Fiber.current
    NB.reactor.attach(mode, io){fiber.resume}
    NB::Fiber.yield
    NB.reactor.detach(mode, io)
  end

  def self.sleep(time)
    NB::Fiber.yield if time.nil?
    return if time <= 0 
    fiber = NB::Fiber.current
    NB.reactor.add_timer(time){fiber.resume}
    NB::Fiber.yield
  end

  def self.defer(io, action, args)
    @@queue << [io, action, args, NB::Fiber.current, NB.reactor]
    NB::Fiber.yield      
  end

end
