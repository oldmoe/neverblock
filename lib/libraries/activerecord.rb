require 'activerecord'

# Patch ActiveRecord to store transaction depth information
# in fibers instead of threads. AR does not support nested
# transactions which makes the job easy.
# We also need to override the scoped methods to store
# the scope in the fiber context
class ActiveRecord::Base

  def single_threaded_scoped_methods #:nodoc:
    scoped_methods = (Fiber.current[:scoped_methods] ||= {})
    scoped_methods[self] ||= []
  end

  def self.transaction(&block)
    increment_open_transactions
    begin
      connection.transaction(Fiber.current['start_db_transaction'], &block)
    ensure
      decrement_open_transactions
    end
  end

  private

  def self.increment_open_transactions #:nodoc:
    open = Fiber.current['open_transactions'] ||= 0
    Fiber.current['start_db_transaction'] = open.zero?
    Fiber.current['open_transactions'] = open + 1
  end

  def self.decrement_open_transactions #:nodoc:
    Fiber.current['open_transactions'] -= 1
  end
  
end

