require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/fixtures/classes'
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")
equire File.dirname(__FILE__) + '/shared/codepoints'

# See redmine #1667
describe "IO#codepoints" do
  ruby_version_is "1.9.2" do
    it_behaves_like(:io_codepoints, :codepoints)

    it "ignores a given block" do
      File.open(IOSpecs.gets_fixtures) do |io|
        enum = io.codepoints{ raise "Never called!"}
        enum.first.should == 86
      end
    end
  end
end
