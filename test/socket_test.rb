require 'minitest/unit'

MiniTest::Unit.autorun

class SocketTest < MiniTest::Unit::TestCase
  def setup
    if ! pid = fork
      require 'socket'
      @server = TCPServer.new('0.0.0.0', 8080)
      STDERR.puts "server started"
      
      loop do
        conn = @server.accept
        STDERR.puts "after server accept"
        conn.recv(5)
        STDERR.puts "after server recv"
        conn.close
        exit
      end
    end
    sleep 0.5
    super
    require '../lib/io'
  end

  def test_tcpsocket_recv
    run_in_reactor do
      s = TCPSocket.new('0.0.0.0', 8080)
      s.send('helloU', Socket::MSG_OOB)
      s.close
    end
  end  

  protected

  def run_in_reactor
    NB.reactor.run do
      NB::Fiber.new do
        yield
        NB.reactor.stop
      end.resume
    end
  end

end

