require "test_helper"

class ParallelBoopsWithoutFixturesTest < ParallelizedNonTransactionalFixturelessTestCase
  100.times do |i|
    test "that boops don't change ##{i}" do
      assert_equal 10, Boop.count
      Boop.create!
      assert_equal 11, Boop.count
    end
  end
end
