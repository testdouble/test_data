require "test_helper"

class ActiveSupport::TestCase
  def self.test_data_mode(mode)
    case mode
    when :factory_bot
      require "factory_bot_rails"
      include FactoryBot::Syntax::Methods

      setup do
        TestData.truncate
      end

      teardown do
        TestData.rollback(:after_data_truncate)
      end
    when :test_data
      setup do
        TestData.load
      end

      teardown do
        TestData.rollback
      end
    end
  end
end

class SomeFactoryUsingTest < ActiveSupport::TestCase
  test_data_mode :factory_bot

  def test_boops
    create(:boop)

    assert_equal 1, Boop.count
  end
end

class SomeTestDataUsingTest < ActionDispatch::IntegrationTest
  test_data_mode :test_data

  def test_boops
    assert_equal 10, Boop.count
  end
end
