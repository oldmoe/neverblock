Gem::Specification.new do |s|
  s.name     = "neverblock"
  s.version  = "0.1.2"
  s.date     = "2008-09-04"
  s.summary  = "Utilities for non-blocking stack components"
  s.email    = "oldmoe@gmail.com"
  s.homepage = "http://github.com/oldmoe/neverblock"
  s.description = "NeverBlock is a collection of classes and modules that help you write evented non-blocking applications in a seemingly blocking mannner."
  s.has_rdoc = true
  s.authors  = ["Muhammad A. Ali", "Ahmed Sobhi", "Osama Brekaa"]
  s.files    = [ 
		"neverblock.gemspec", 
		"README", 
		"lib/neverblock.rb", 
		"lib/never_block.rb", 
		"lib/neverblock-pg.rb", 
		"lib/neverblock-mysql.rb", 
		"lib/never_block/extensions/fiber_extensions.rb", 
		"lib/never_block/pool/fiber_pool.rb", 
		"lib/never_block/pool/fibered_connection_pool.rb",
    "lib/never_block/frameworks/rails.rb",
    "lib/never_block/frameworks/activerecord.rb",
    "lib/never_block/servers/thin.rb",
    "lib/never_block/db/fibered_postgres_connection.rb",
    "lib/never_block/db/pooled_fibered_postgres_connection.rb",
    "lib/never_block/db/fibered_mysql_connection.rb",
    "lib/never_block/db/pooled_fibered_mysql_connection.rb",
    "lib/active_record/connection_adapters/neverblock_postgresql_adapter.rb",
    "lib/active_record/connection_adapters/neverblock_mysql_adapter.rb"
  ]
  s.rdoc_options = ["--main", "README"]
  s.extra_rdoc_files = ["README"]
end


