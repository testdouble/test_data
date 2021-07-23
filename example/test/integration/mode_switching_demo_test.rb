require "test_helper"

class ModeSwitchingTestCase < ActiveSupport::TestCase
  self.use_transactional_tests = false

  def self.test_data_mode(mode)
    if mode == :factory_bot
      require "factory_bot_rails"
      include FactoryBot::Syntax::Methods

      setup do
        TestData.uses_clean_slate
      end
    elsif mode == :test_data
      setup do
        TestData.uses_test_data
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
