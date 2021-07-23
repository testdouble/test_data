require "test_helper"

class FixturesUsingTest < ActiveSupport::TestCase
  def test_tries_to_load_rails_fixtures_with_test_data
    error = assert_raises(TestData::Error) do
      TestData.uses_rails_fixtures(self)
    end
    assert_match "'TestData.uses_rails_fixtures(self)' depends on Rails' default fixture-loading behavior being disabled by calling 'TestData.prevent_rails_fixtures_from_loading_automatically!' as early as possible (e.g. near the top of your test_helper.rb), but it looks like it was never called", error.message
  end
end
