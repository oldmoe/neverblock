require 'timeout'

module Timeout
	def timeout(timeout_value, &block)
		fiber = Fiber.current

		fiber['timeout_value'] = timeout_value
		fiber['starting_time'] = Time.now.to_i
		block.call
		timer.cancel
	end
end


