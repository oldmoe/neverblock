require 'fiber'

class Fiber
  
  #Attribute Reference--Returns the value of a fiber-local variable, using either a symbol or a string name. If the specified variable does not exist, returns nil.
  def [](key)
    local_fiber_variables[key]
  end
  
  #Attribute Assignment--Sets or creates the value of a fiber-local variable, using either a symbol or a string. See also Fiber#[].
  def []=(key,value)
    local_fiber_variables[key] = value
  end
  
  private
  
  def local_fiber_variables
    @local_fiber_variables ||= {}
  end    
end

