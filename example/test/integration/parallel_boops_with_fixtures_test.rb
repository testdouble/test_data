require "test_helper"

class ParallelBoopsWithFixturesTest < ParallelizedTransactionalFixturefullTestCase
  100.times do |i|
    test "that boops don't change ##{i}" do
      assert_equal 12, Boop.count
      Boop.create!
      assert_equal 13, Boop.count
    end
  end
end
