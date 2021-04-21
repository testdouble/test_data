require "test_helper"

class ModeSwitchingTestCase < ActiveSupport::TestCase
  def self.test_data_mode(mode)
    if mode == :factory_bot
      require "factory_bot_rails"
      include FactoryBot::Syntax::Methods

      setup do
        TestData.rollback(:before_data_load)
        ActiveRecord::Base.connection.begin_transaction(joinable: false, _lazy: false)
      end

      teardown do
        ActiveRecord::Base.connection.rollback_transaction
      end

    elsif mode == :test_data
      self.use_transactional_tests = false

      setup do
        TestData.load
      end

      teardown do
        TestData.rollback
      end
    end
  end
end

class FactoryModeTest < ModeSwitchingTestCase
  test_data_mode :factory_bot

  def test_boops
    create(:boop)

    assert_equal 1, Boop.count
  end
end

class TestDataModeTest < ModeSwitchingTestCase
  test_data_mode :test_data

  def test_boops
    assert_equal 10, Boop.count
  end
end
