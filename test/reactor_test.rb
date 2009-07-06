require 'minitest/unit'

MiniTest::Unit.autorun

class NeverBlockReactorTest < MiniTest::Unit::TestCase
  def setup
    super
    require '../lib/neverblock'    
    @reactor = NeverBlock.reactor
  end

  def test_will_return_a_reactor
    refute_nil @reactor
    assert_kind_of Reactor::Base, NeverBlock.reactor
  end

  def test_will_be_visible_in_a_fiber
    Fiber.new do
      assert_equal @reactor, NeverBlock.reactor
    end.resume
  end

  def test_each_thread_will_have_different_reactor
    Thread.new do
      refute_equal @reactor, NeverBlock.reactor
    end
  end

end



# test that NeverBlock.reactor returns a reactor object

