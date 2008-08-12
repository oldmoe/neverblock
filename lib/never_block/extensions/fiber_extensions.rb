require 'fiber'

class Fiber
  def [](key)
    local_fiber_variables[key]
  end
  
  def []=(key,value)
    local_fiber_variables[key] = value
  end
  
  def local_fiber_variables
    @local_fiber_variables ||= {}
  end  
  private :local_fiber_variables
end

