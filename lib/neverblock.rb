$:.unshift File.expand_path(File.dirname(__FILE__))

require 'fiber'
require 'never_block/extensions/fiber_extensions'

module NeverBlock
end

NB = NeverBlock

