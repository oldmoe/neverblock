# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2009 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

require 'thread'
require File.expand_path(File.dirname(__FILE__)+'/io')

class File < IO
  
  def self.neverblock(*methods)
    methods.each do |method|  
      class_eval %{
        def #{method}(*args)
          return rb_#{method}(*args) unless NB.neverblocking?
          NB.defer(self, :#{method}, args)
        end
      }
    end
  end
  
  neverblock :syswrite, :sysread, :write, :read, :readline, 
             :readlines, :readchar, :gets, :getc, :print
               
end
