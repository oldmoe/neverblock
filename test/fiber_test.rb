require 'minitest/unit'

MiniTest::Unit.autorun

class NeverBlockFiberTest < MiniTest::Unit::TestCase
  def setup
    super
    require '../lib/neverblock'
    @fiber = NeverBlock::Fiber.new{ x = NB::Fiber.yield 1 }
  end

  def test_will_set_and_get
    @fiber[:x] = 5
    assert_equal @fiber[:x], 5
  end

  def test_starts_with_neverblock
    assert @fiber[:neverblock]
  end

  def test_yield_will_return
    assert_equal @fiber.resume, 1
    assert_equal @fiber.resume(5), 5
  end

  def test_yield_will_raise
    assert_equal @fiber.resume, 1
    assert_raises(ZeroDivisionError){@fiber.resume(ZeroDivisionError.new)} 
  end

end



# test that NeverBlock.reactor returns a reactor object

