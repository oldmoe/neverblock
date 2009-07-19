Gem::Specification.new do |s|
  s.name     = "neverblock"
  s.version  = "1.0"
  s.date     = "2009-07-16"
  s.summary  = "Utilities for non-blocking stack components"
  s.email    = "oldmoe@gmail.com"
  s.homepage = "http://github.com/oldmoe/neverblock"
  s.description = "NeverBlock is a collection of classes and modules that help you write evented non-blocking applications in a seemingly blocking mannner."
  s.has_rdoc = true
  s.authors  = ["Muhammad A. Ali", "Ahmed Sobhi", "Osama Brekaa"]
  s.files    = [ 
		"neverblock.gemspec", 
		"README",
                "lib/neverblock/core/reactor.rb",
                "lib/neverblock/core/fiber.rb",
                "lib/neverblock/core/pool.rb",
                "lib/neverblock/core/system/system.rb",
                "lib/neverblock/core/system/timeout.rb",
                "lib/neverblock/io/db/pool.rb",
                "lib/neverblock/io/db/drivers/mysql.rb",
                "lib/neverblock/io/db/drivers/postgres.rb",
                "lib/neverblock/io/db/connection.rb",
                "lib/neverblock/io/db/fibered_connection_pool.rb",
                "lib/neverblock/io/db/fibered_mysql_connection.rb",
                "lib/neverblock/io/file.rb",
                "lib/neverblock/io/socket.rb",
                "lib/neverblock/io/io.rb",
                "lib/system.rb",
                "lib/neverblock.rb",
                "lib/never_block.rb",
                "lib/neverblock_io.rb"

  ]
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]
  s.add_dependency('reactor', '>= 0.2.3')
end


