require 'reactor'

module NeverBlock

  @@reactors = {}

  def self.reactor
    @@reactors[Thread.current.object_id] ||= ::Reactor::Base.new
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

  def self.wait(mode, io)
    fiber = NB::Fiber.current
    NB.reactor.attach(mode, io){NB.reactor.detach(mode, io);fiber.resume}
    NB::Fiber.yield
  end

end
