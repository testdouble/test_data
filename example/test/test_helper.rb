ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Noncommittal.start!

class SerializedNonTransactionalTestCase < ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  setup do
    TestData.load
  end

  teardown do
    TestData.rollback
  end
end
