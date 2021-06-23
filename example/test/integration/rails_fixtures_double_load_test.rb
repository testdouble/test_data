require "test_helper"

class FixturesUsingTest < ActiveSupport::TestCase
  def test_tries_to_load_rails_fixtures_with_test_data
    error = assert_raises(TestData::Error) do
      TestData.load_rails_fixtures
    end
    assert_match "", error.message
  end
end
