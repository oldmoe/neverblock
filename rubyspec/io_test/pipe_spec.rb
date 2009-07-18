require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")
describe "IO.pipe" do
  it "creates a two-ended pipe" do
    r, w = IO.pipe
    w.puts "test_create_pipe\\n"
    w.close
    r.read(16).should == "test_create_pipe"
    r.close
  end

  it "returns two IO objects" do
    r,w = IO.pipe
    r.should be_kind_of(IO)
    w.should be_kind_of(IO)
  end
end


