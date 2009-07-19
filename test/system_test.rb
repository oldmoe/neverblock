require 'minitest/unit'

MiniTest::Unit.autorun

class SystemTest < MiniTest::Unit::TestCase
  def setup
    super
    require '../lib/system'
 
  end
  def test_sleep
    run_in_reactor do
      t = Time.now
      sleep(0.1)
      span = Time.now - t
      assert_in_delta span, 0.1, 0.01
    end
  end

  def test_backticks
    assert_equal backticks("echo", "toot"), "toot\n"
    assert_raises(Errno::ENOENT){backticks("ll")}
  end

  def test_system
    NB::Fiber.new do
      assert system("ls")
      refute system("ls whatisthat")
      assert_nil system("ll")
    end.resume
  end

  def test_timed_out
    run_in_reactor do
      t = Time.now
      assert_raises(Timeout::Error) do 
        Timeout::timeout(1) do
          sleep(2)
          #raise Timeout::Error
        end
      end
      span = Time.now - t
      assert_in_delta span, 1, 0.1
    end
  end


  def test_didnt_timeout
    run_in_reactor do
      t = Time.now
      Timeout::timeout(2) do
        sleep(1)
      end
      span = Time.now - t
      assert_in_delta span, 1, 0.1
    end
  end

  def test_nested_timeouts_raise_exception
    run_in_reactor do
      t = Time.now
      assert_raises(Timeout::Error) do 
        Timeout::timeout(1) do
          Timeout::timeout(1) do
            sleep(2)
          end
        end
      end
      span = Time.now - t
      assert_in_delta span, 1, 0.1
    end
  end

  protected

  def run_in_reactor(&block)
    NB::Fiber.new do
      NB.reactor.add_timer(0.1){block.call; NB.reactor.stop}
    end.resume
    NB.reactor.run
  end

end

