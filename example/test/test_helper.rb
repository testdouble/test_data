ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  def setup
    TestData.load_data_dump
  end

  def teardown
    TestData.rollback
  end
end
