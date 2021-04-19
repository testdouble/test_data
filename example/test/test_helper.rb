ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class SerializedNonTransactionalTestCase < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  def setup
    TestData.load_data_dump
  end

  def teardown
    TestData.rollback
  end
end

class ParallelizedTransactionalFixturefullTestCase < ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  self.use_transactional_tests = true
  fixtures :all

  def setup
    TestData.load_data_dump
  end

  # use_transactional_tests will cause a single rollback on teardown
end

class ParallelizedNonTransactionalFixturelessTestCase < ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)
  self.use_transactional_tests = false

  def setup
    TestData.load_data_dump
  end

  def teardown
    TestData.rollback
  end
end
