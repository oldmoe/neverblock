
require File.expand_path(File.dirname(__FILE__)+'/../../../neverblock')

module Kernel

  alias_method :rb_sleep, :sleep

  def sleep(time=nil)
    return rb_sleep(time) unless NB.neverblocking?
    NB.sleep(time)
  end

  alias_method :rb_system, :system

  def system(cmd, *args)
    return rb_system(cmd, *args) unless NB.neverblocking?
    begin
      backticks(cmd, *args)
      result = $?.exitstatus
      return true if result.zero?
      return nil if result == 127
      return false
    rescue Errno::ENOENT => e
      return nil
    end
  end

  def backticks(cmd, *args)
    myargs = "#{cmd} "
    myargs << args.join(' ') if args
    res = ''    
    IO.popen(myargs) do |f|
      res << f.read
    end
    res
  end
  
end
