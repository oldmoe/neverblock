require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")
describe "IO.sysopen" do

  before :all do
    @filename = tmp("rubinius-spec-io-sysopen-#{$$}.txt")
  end

  after :all do
    File.unlink @filename
  end


  it "returns the file descriptor for a given path" do
    fd = IO.sysopen(@filename, "w")
    fd.should be_kind_of(Fixnum)
    fd.should_not equal(0)
  end

  it "works on directories" do
    fd = IO.sysopen(tmp(""))    # /tmp
    fd.should be_kind_of(Fixnum)
    fd.should_not equal(0)
  end

  it "accepts a mode as second argument" do
    fd = 0
    lambda { fd = IO.sysopen(@filename, "w") }.should_not raise_error
    fd.should_not equal(0)
  end

  it "accepts permissions as third argument" do
    fd = IO.sysopen(@filename, "w", 777)
    fd.should_not equal(0)
  end
end
