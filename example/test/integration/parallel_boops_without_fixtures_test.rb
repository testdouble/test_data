require "test_helper"

class ParallelizedNonTransactionalFixturelessTestCase < ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  self.use_transactional_tests = false

  setup do
    TestData.uses_test_data
  end
end

class ParallelBoopsWithoutFixturesTest < ParallelizedNonTransactionalFixturelessTestCase
  100.times do |i|
    test "that boops don't change ##{i}" do
      assert_equal 10, Boop.count
      Boop.create!
      assert_equal 11, Boop.count
    end
  end
end
