require "test_helper"

TestData.prevent_rails_fixtures_from_loading_automatically!

class FixturesUsingTest < ActiveSupport::TestCase
  setup do
    TestData.load_rails_fixtures
  end

  def test_has_fixture_boops
    assert_equal 2, Boop.count
  end

  def test_even_explicitly_loading_test_data_will_truncate_and_then_load_fixtures
    TestData.load
    TestData.load_rails_fixtures

    assert_equal 2, Boop.count
  end

  def test_load_and_rollback_leaves_them_as_is
    boop = Boop.first
    original_created_at_time = boop.created_at
    a_year_ago = 1.year.ago

    boop.update!(created_at: a_year_ago)

    assert_equal Boop.find(boop.id).created_at, a_year_ago)

    # Now after rollback
    TestData.rollback(:after_load_rails_fixtures)

    assert_equal Boop.find(boop.id).created_at, original_created_at_time
  end

  teardown do
    TestData.rollback(:after_load_rails_fixtures)
  end
end
