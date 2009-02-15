module Kernel
	def sleep(time=nil)
		fiber = Fiber.current
		EM.set_timer(time) do
			fiber.resume
		end unless time.nil?
		Fiber.yield
	end
end
