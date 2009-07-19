require File.expand_path(File.dirname(__FILE__)+'/../../../io')
NB::Fiber.new do
    data = "*" * (3) # HACK IO::BufferSize
    r,w = IO.pipe
    w.write data
    w.close
    puts r.read(5).length

     NB.reactor.add_timer(3){NB.reactor.stop}
    NB.reactor.run

end.resume
