require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")

describe "IO" do
  it "includes File::Constants" do
    IO.include?(File::Constants).should == true
  end

  it "for_fd takes two arguments" do
	IO.method(:for_fd).arity.should == -1
  end
end
