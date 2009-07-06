require 'neverblock' unless defined?(NeverBlock)

# Rails tries to protect dispatched actions
# by wrapping them in a synchronized code
# block, since fibers hate synchronized
# blocks we will trick the guard and
# transform it (without it knowing) to
# something more subtle

require 'thread'
# now you synchronize
class Mutex
  def synchronize(&block)
    # now you don't!
    block.call
  end
end

require 'action_controller'
class ActionController::Base

  # Mark some actions to execute in a blocking manner overriding the default
  # settings.
  # Example:
  #   class UsersController < ApplicationController
  #     .
  #     allowblock :index
  #     .
  #   end
  def self.allowblock(*actions)
    actions.each do |action|
      class_eval <<-"end_eval"
        def allowblock_#{action}
          status = Fiber.current[:neverblock]
          Fiber.current[:neverblock] = false
          yield
          Fiber.current[:neverblock] = status
        end
        around_filter :allowblock_#{action}, :only => [:#{action}]
      end_eval
    end
  end

  # Mark some actions to execute in a non-blocking manner overriding the default
  # settings.
  # Example:
  #   class UsersController < ApplicationController
  #     .
  #     allowblock :index
  #     .
  #   end
  def self.neverblock(*actions)
    actions.each do |action|
      class_eval <<-"end_eval"
        def neverblock_#{action}
          status = Fiber.current[:neverblock]
          Fiber.current[:neverblock] = true
          yield
          Fiber.current[:neverblock] = status
        end
        around_filter :allowblock_#{action}, :only => [:#{action}]
      end_eval
    end
  end
end
