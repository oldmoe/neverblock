$:.unshift File.expand_path(File.dirname(__FILE__))

require 'fiber'
require 'never_block/extensions/fiber_extensions'
require 'never_block/pool/fiber_pool'
require 'never_block/pool/fibered_connection_pool'

module NeverBlock
end

NB = NeverBlock