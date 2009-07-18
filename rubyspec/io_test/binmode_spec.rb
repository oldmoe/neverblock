require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")

describe "IO#binmode" do
  before :each do
    @filename = tmp("IO_binmode_file")
    @file = File.open(@filename, "w")
  end

  after :each do
    @file.close
    File.unlink @filename
  end
  
  it "does not raise any errors on closed stream" do
    lambda { IOSpecs.closed_file.binmode }.should_not raise_error()
  end

  # Even if it does nothing in Unix it should not raise any errors.
  it "puts a stream in binary mode" do
    lambda { @file.binmode }.should_not raise_error
  end
end
