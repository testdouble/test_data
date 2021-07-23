require "test_helper"

TestData.prevent_rails_fixtures_from_loading_automatically!

class FixtureFreeTestData < ActiveSupport::TestCase
  fixtures :boops # why not

  setup do
    TestData.uses_test_data
  end

  def test_has_no_fixture_boops
    assert_equal 15, Boop.count
  end
end

class FixturesUsingTest < ActiveSupport::TestCase
  fixtures :boops

  setup do
    TestData.uses_rails_fixtures(self)
  end

  def test_has_fixture_boops
    assert boops(:boop_1).persisted?
    assert_equal 2, Boop.count
  end

  def test_does_not_get_the_other_fixture_accessor
    assert_raises(NameError) { method(:pants) }
  end

  def test_even_explicitly_loading_test_data_will_truncate_and_then_load_fixtures
    TestData.uses_test_data
    TestData.uses_rails_fixtures(self)

    assert_equal 2, Boop.count
  end

  def test_load_and_rollback_leaves_them_as_is
    boop = Boop.first
    original_created_on = boop.created_at.to_date
    a_year_ago = 1.year.ago.to_date

    boop.update!(created_at: a_year_ago)

    assert_equal Boop.find(boop.id).created_at.to_date, a_year_ago

    # Now trigger a rollback to the fixtures point
    TestData.uses_rails_fixtures(self)

    assert_equal Boop.find(boop.id).created_at.to_date, original_created_on
  end
end

class SomeFixturesAndSomeTestDataInOneClassTest < ActiveSupport::TestCase
  i_suck_and_my_tests_are_order_dependent!
  fixtures :all

  def test_fixtures_work
    TestData.uses_rails_fixtures(self)

    assert_equal Date.civil(2020, 1, 1), boops(:boop_1).updated_at.to_date
    assert_equal "Levi", pants(:pant_1).brand
  end

  def test_that_rewinds_to_test_data
    TestData.uses_test_data

    assert_equal 15, Boop.count
  end

  def test_that_rewinds_to_the_very_start
    TestData.uninitialize

    assert_equal 0, Boop.count
  end

  def test_fixtures_get_reloaded_because_cache_is_cleared
    TestData.uses_rails_fixtures(self)

    assert_equal Date.civil(2019, 1, 1), boops(:boop_2).updated_at.to_date
    assert_equal "Wrangler", pants(:pant_2).brand
  end
end

class PantsFixturesTest < ActiveSupport::TestCase
  fixtures :pants

  setup do
    TestData.uses_rails_fixtures(self)
  end

  def test_has_fixture_pants
    assert_equal 2, Pant.count
  end

  def test_does_not_get_the_other_fixture_accessor
    assert_raises(NameError) { method(:boops) }
  end
end

class FixtureTestPassingTheWrongThingTest < ActiveSupport::TestCase
  def test_doing_it_wrong
    error = assert_raises(TestData::Error) do
      TestData.uses_rails_fixtures(ActiveRecord::Base)
    end
    assert_match "'TestData.uses_rails_fixtures(self)' must be passed a test instance that has had ActiveRecord::TestFixtures mixed-in (e.g. `TestData.uses_rails_fixtures(self)` in an ActiveSupport::TestCase `setup` block), but the provided argument does not respond to 'setup_fixtures'", error.message
  end
end
