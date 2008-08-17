# Author::    Mohammad A. Ali  (mailto:oldmoe@gmail.com)
# Copyright:: Copyright (c) 2008 eSpace, Inc.
# License::   Distributes under the same terms as Ruby

$:.unshift File.expand_path(File.dirname(__FILE__))

require 'fiber'
require 'never_block/extensions/fiber_extensions'
require 'never_block/pool/fiber_pool'
require 'never_block/pool/fibered_connection_pool'

module NeverBlock
end

NB = NeverBlock