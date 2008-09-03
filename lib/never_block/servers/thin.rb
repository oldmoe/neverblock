require 'rubygems' 
require 'neverblock'
require 'thin'

module Thin
  
  # Patch the thin server to use 
  # NeverBlock::Pool::FiberPool
  # to be able to wrap requests
  # in fibers
  class Server

    DEFAULT_FIBER_POOL_SIZE = 50

    def fiber_pool
      @fiber_pool ||= NB::Pool::FiberPool.new(DEFAULT_FIBER_POOL_SIZE)
    end  

  end # Server

  # A request is processed by wrapping it
  # in a fiber from the fiber pool. If all
  # the fibers are busy the request will
  # wait in a queue to be picked up later.
  # Meanwhile, the server will still be
  # processing requests
  class Connection < EventMachine::Connection

    def process
        @request.threaded = false
        @backend.server.fiber_pool.spawn{post_process(pre_process)}
    end
    
  end # Connection

  module Backends
    class Base
      def config
        # EM.epoll
        # Set the maximum number of socket descriptors that the server may open.
        # The process needs to have required privilege to set it higher the 1024 on
        # some systems.
        @maximum_connections = EventMachine.set_descriptor_table_size(@maximum_connections) unless Thin.win?
      end
    end
  end # Backends

end # Thin
