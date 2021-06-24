require "test_helper"

TestData.prevent_rails_fixtures_from_loading_automatically!

class ActiveSupport::TestCase
  fixtures :all
end

class FixtureFreeTestData < ActiveSupport::TestCase
  setup do
    TestData.load
  end

  def test_has_no_fixture_boops
    assert_equal 15, Boop.count
  end

  teardown do
    TestData.rollback
  end
end

class FixturesUsingTest < ActiveSupport::TestCase
  setup do
    TestData.load_rails_fixtures(self)
  end

  def test_has_fixture_boops
    assert_equal 2, Boop.count
  end

  def test_even_explicitly_loading_test_data_will_truncate_and_then_load_fixtures
    TestData.load
    TestData.load_rails_fixtures(self)

    assert_equal 2, Boop.count
  end

  def test_load_and_rollback_leaves_them_as_is
    boop = Boop.first
    original_created_at_time = boop.created_at
    a_year_ago = 1.year.ago

    boop.update!(created_at: a_year_ago)

    assert_equal Boop.find(boop.id).created_at, a_year_ago

    # Now after rollback
    TestData.rollback(:after_load_rails_fixtures)

    assert_equal Boop.find(boop.id).created_at, original_created_at_time
  end

  teardown do
    TestData.rollback(:after_load_rails_fixtures)
  end
end

class AnotherFixturesUsingTest < ActiveSupport::TestCase
  setup do
    TestData.load_rails_fixtures(self)
  end

  def test_boops_api_works
    assert_equal Date.civil(2020, 1, 1), boops(:boop_1).updated_at.to_date
  end

  teardown do
    TestData.rollback(:after_load_rails_fixtures)
  end
end

class FixtureTestPassingTheWrongThingTest < ActiveSupport::TestCase
  def test_doing_it_wrong
    error = assert_raises(TestData::Error) do
      TestData.load_rails_fixtures(ActiveRecord::Base)
    end
    assert_match "'TestData.load_rails_fixtures' must be passed a test instance that has had ActiveRecord::TestFixtures mixed-in (e.g. `TestData.load_rails_fixtures(self)` in an ActiveSupport::TestCase `setup` block), but the provided argument does not respond to 'setup_fixtures'", error.message
  end
end
