# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2009 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

require 'fiber'
require File.expand_path(File.dirname(__FILE__)+'/../../never_block')

class NeverBlock::Fiber < Fiber

  def initialize(neverblock = true, &block)
    self[:neverblock] = neverblock
    super()
  end


  #Attribute Reference--Returns the value of a fiber-local variable, using
  #either a symbol or a string name. If the specified variable does not exist,
  #returns nil.
  def [](key)
    local_fiber_variables[key]
  end
  
  #Attribute Assignment--Sets or creates the value of a fiber-local variable,
  #using either a symbol or a string. See also Fiber#[].
  def []=(key,value)
    local_fiber_variables[key] = value
  end
  
  #Sending an exception instance to resume will yield the fiber
  #and then raise the exception. This is necessary to raise exceptions
  #in their correct context.
  def self.yield(*args)
    result = super
    raise result if result.is_a? Exception
    result
  end

  private
  
  def local_fiber_variables
    @local_fiber_variables ||= {}
  end

end

