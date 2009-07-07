require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")

describe "IO#ioctl" do
  it "raises IOError on closed stream" do
    lambda { IOSpecs.closed_file.ioctl(5, 5) }.should raise_error(IOError)
  end
end
