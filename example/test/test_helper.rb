ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: 1)
  self.use_transactional_tests = false

  def before_setup
    puts "before_setup: test_data"
    TestData.load_data_dump
    super
  end

  def after_teardown
    super
    puts "after_setup: test_data"
    TestData.rollback
  end
end
