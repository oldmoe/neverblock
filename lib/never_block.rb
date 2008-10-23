# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2008 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

$:.unshift File.expand_path(File.dirname(__FILE__))

unless defined? Fiber
  require 'thread'
  require 'singleton'
  class FiberError < StandardError; end
  class Fiber
    def initialize
      raise ArgumentError, 'new Fiber requires a block' unless block_given?
 
      @yield = Queue.new
      @resume = Queue.new

      @thread = Thread.new{ @yield.push [ *yield(*@resume.pop) ] }
      @thread.abort_on_exception = true
      @thread[:fiber] = self
    end
    attr_reader :thread
 
    def resume *args
      raise FiberError, 'dead fiber called' unless @thread.alive?
      @resume.push(args)
      result = @yield.pop
      result.size > 1 ? result : result.first
    end
    
    def yield *args
      @yield.push(args)
      result = @resume.pop
      result.size > 1 ? result : result.first
    end
    
    def self.yield *args
      raise FiberError, "can't yield from root fiber" unless fiber = Thread.current[:fiber]
      fiber.yield(*args)
    end
 
    def self.current
      Thread.current[:fiber] or raise FiberError, 'not inside a fiber'
    end
 
    def inspect
      "#<#{self.class}:0x#{self.object_id.to_s(16)}>"
    end
  end

  class RootFiber < Fiber
    include Singleton
    def initialize
    end

    def resume *args
      raise FiberError, "can't resume root fiber"
    end

    def yield *args
      raise FiberError, "can't yield from root fiber"
    end
  end

  #attach the root fiber to the main thread
  Thread.main[:fiber] = RootFiber.instance
else
  require 'fiber'
end

require 'never_block/extensions/fiber_extensions'
require 'never_block/pool/fiber_pool'
require 'never_block/pool/fibered_connection_pool'

module NeverBlock

  # Checks if we should be working in a non-blocking mode
  def self.neverblocking?
    Fiber.respond_to?(:current) && Fiber.current[:neverblock]
  end

  def self.event_loop_available?
    defined?(EM) && EM.reactor_running?
  end

  # The given block will run its queries either in blocking or non-blocking
  # mode based on the first parameter
  def self.neverblock(nb = true, &block)
    status = Fiber.current[:neverblock]
    Fiber.current[:neverblock] = nb
    block.call
    Fiber.current[:neverblock] = status
  end
end

NB = NeverBlock
