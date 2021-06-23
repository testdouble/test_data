require "test_helper"

class ParallelizedTransactionalFixturefullTestCase < ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  self.use_transactional_tests = true
  fixtures :all

  setup do
    TestData.load
  end

  teardown do
    TestData.rollback
  end
end

class ParallelBoopsWithFixturesTest < ParallelizedTransactionalFixturefullTestCase
  100.times do |i|
    test "that boops don't change ##{i}" do
      assert_equal 12, Boop.count
      Boop.create!
      assert_equal 13, Boop.count
    end
  end
end
