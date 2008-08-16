require 'actionpack'

# Rails tries to protect dispatched actions
# by wrapping them in a synchronized code
# block, since fibers hate synchronized
# blocks we will trick the guard and
# transform it (without it knowing) to
# something more subtle

class ActionController::Dispatcher

  # let's show this guard who is
  # the man of the house
  @@guard = Object.new

  # now you synchronize
  def @@guard.synchronize(&block)
    # now you don't!
    block.call
  end
end
