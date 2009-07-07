 require File.expand_path(File.dirname(__FILE__) + "/../never_block/io/neverblock_io")
 require File.expand_path(File.dirname(__FILE__) + "/../never_block/socket/socket_neverblock")
 require File.expand_path(File.dirname(__FILE__) + "/../neverblock")
data = "*" * (8096 * 2 + 1024) # HACK IO::BufferSize
File.open "tests.txt", 'w' do |io| io.write "1234567890" end
buffer=""
puts "object_id: #{buffer.object_id}"
File.open "tests.txt", 'r' do |io| x=io.read(11,buffer) ; puts buffer end

