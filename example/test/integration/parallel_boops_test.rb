require "test_helper"

class ParallelBoopsTest < ActionDispatch::IntegrationTest
  parallelize(workers: :number_of_processors)
  self.use_transactional_tests = true
  fixtures :all

  100.times do |i|
    test "that boops don't change ##{i}" do
      assert_equal 12, Boop.count
      Boop.create!
      assert_equal 13, Boop.count
    end
  end
end
