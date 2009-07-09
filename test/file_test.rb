require 'minitest/unit'
require 'json'

MiniTest::Unit.autorun

class NBFileTest < MiniTest::Unit::TestCase
  def setup
    super
    require '../lib/neverblock'
    @block = proc   do
      3000.times{ { :x=>['xxxxxxx'*4], :y=>{:c=>['a',:b]}, :z=> 'hi there'*18 }.to_json }
    end
    @t = Time.now
  end

  def teardown
    puts Time.now - @t
  end
=begin
  def test_blocked_by_syswrite
    threads = []
    t= Time.now
    5.times do |i|
      #threads << Thread.new do
        f = File.new("file_test/#{i}","w")
        10.times do
          @block.call
          f.syswrite("data"*1024*1024*2)
        end
        f.close
      #end
      #threads.each{|t|t.join} 
    end
  end
=end
  def test_blocked_by_sysread
    puts "srb"
    5.times do |i|
      f = File.new("file_test/#{i}","r")
      10.times do
        @block.call
        f.sysread(8*1024*1024)
      end
      f.close
    end
  end
=begin
  def test_not_blocked_by_syswrite
    count = 5
    done = 0
    run_in_reactor do
      count.times do |i|
        NB::Fiber.new do
          f = File.new("file_test/#{i}","w")
          10.times do
            @block.call
            f.syswrite("data"*1024*1024*2)
          end
          f.close
          if (done = done + 1) == count
            NB.reactor.stop
          end
        end.resume
      end
    end
  end
=begin
#=end
  def test_not_blocked_by_sysread
    puts "srnb"
    count = 5
    done = 0
    run_in_reactor do
      count.times do |i|
        f = File.new("file_test/#{i}","r")
        10.times do
          @block.call
          f.sysread(8*1024*1024)
        end
        f.close
        if (done = done + 1) == count
          NB.reactor.stop
        end
      end
    end
  end
=end
  protected

  def run_in_reactor
    NB.reactor.run do 
      yield
    end
  end

end

