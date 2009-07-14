require 'minitest/unit'
require '../lib/neverblock'
require 'activerecord'
require '../lib/core/io/db/fibered_mysql_connection'

class Book < ActiveRecord::Base

end


MiniTest::Unit.autorun



class ActiverecordTest < MiniTest::Unit::TestCase
  def setup
    super
    ActiveRecord::Base.configurations = {
      'test' => { 
        :adapter  => 'neverblock_mysql', 
        :username => 'root', 
        :password => 'root', 
        :encoding => 'utf8', 
        :database => 'test',
        :pool => 8
      }
    }
    ActiveRecord::Base.establish_connection 'test'
  end

  def test_concurrency
    count = 17
    done = 0
    t = Time.now
    NB.reactor.run do
      (1..count).each do
       NB::Fiber.new do
          Book.find_by_sql("select sleep(0.2) as sleep")
          ActiveRecord::Base.connection_pool.release_connection
          done += 1
          puts done
          if done == count
            NB.reactor.stop
          end
        end.resume
      end
    end

    assert_in_delta Time.now - t, 0.6, 0.2
  end

end
