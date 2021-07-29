require "test_helper"

TestData.config do |config|
  config.after_test_data_load { MetaBoop.refresh_materialized_view }
  config.after_test_data_truncate(-> { MetaBoop.refresh_materialized_view })
  config.after_rails_fixture_load { MetaBoop.refresh_materialized_view }
end

TestData.prevent_rails_fixtures_from_loading_automatically!
MetaBoop.refresh_materialized_view # count = 1

class TestDataHooksTest < ActiveSupport::TestCase
  fixtures :all
  i_suck_and_my_tests_are_order_dependent!

  def test_uses_test_data_hook
    assert_equal 1, MetaBoop.refresh_materialized_view_count
    MetaBoop.reset_refresh_materialized_view_count

    # Materialized view is refreshed and called 1 time
    TestData.uses_test_data
    assert_equal 15, Boop.count
    assert_equal 15, MetaBoop.count
    assert_equal 1, MetaBoop.refresh_materialized_view_count
    MetaBoop.reset_refresh_materialized_view_count

    # Rollbacks also rollback to materialized view changes without calling again
    Boop.create!(other_boop: Boop.new)
    assert_equal 16, Boop.count
    assert_equal 15, MetaBoop.count
    MetaBoop.refresh_materialized_view
    assert_equal 16, MetaBoop.count
    assert_equal 1, MetaBoop.refresh_materialized_view_count
    TestData.uses_test_data
    assert_equal 15, Boop.count
    assert_equal 15, MetaBoop.count
    assert_equal 1, MetaBoop.refresh_materialized_view_count
    MetaBoop.reset_refresh_materialized_view_count

    # The same hook also works when cleaning slates
    TestData.uses_clean_slate
    assert_equal 0, Boop.count
    assert_equal 0, MetaBoop.count
    assert_equal 1, MetaBoop.refresh_materialized_view_count
    Boop.create!(other_boop: Boop.new)
    MetaBoop.refresh_materialized_view
    assert_equal 1, Boop.count
    assert_equal 1, MetaBoop.count
    assert_equal 2, MetaBoop.refresh_materialized_view_count
    TestData.uses_clean_slate
    assert_equal 0, Boop.count
    assert_equal 0, MetaBoop.count
    assert_equal 2, MetaBoop.refresh_materialized_view_count
    MetaBoop.reset_refresh_materialized_view_count

    # The same hook works with fixtures
    TestData.uses_rails_fixtures(self)
    assert_equal 2, Boop.count
    assert_equal 2, MetaBoop.count
    assert_equal 1, MetaBoop.refresh_materialized_view_count
    Boop.first.delete
    assert_equal 1, Boop.count
    assert_equal 2, MetaBoop.count
    MetaBoop.refresh_materialized_view
    assert_equal 1, MetaBoop.count
    assert_equal 2, MetaBoop.refresh_materialized_view_count
    TestData.uses_rails_fixtures(self)
    assert_equal 2, Boop.count
    assert_equal 2, MetaBoop.count
    assert_equal 2, MetaBoop.refresh_materialized_view_count
    MetaBoop.reset_refresh_materialized_view_count

    # Rewinding two steps will not call refresh materialized views
    TestData.uses_test_data
    assert_equal 15, Boop.count
    assert_equal 15, MetaBoop.count
    assert_equal 0, MetaBoop.refresh_materialized_view_count
  end

  def test_that_hooks_require_valid_settings
    foo = Struct.new(:thing)
    assert_raises(TestData::Error) { TestData.config.after_test_data_load(nil) }
    assert_raises(TestData::Error) { TestData.config.after_test_data_truncate(nil) }
    assert_raises(TestData::Error) { TestData.config.after_rails_fixture_load(nil) }
    assert_raises(TestData::Error) { TestData.config.after_test_data_load(foo) }
    assert_raises(TestData::Error) { TestData.config.after_test_data_truncate(foo) }
    assert_raises(TestData::Error) { TestData.config.after_rails_fixture_load(foo) }
  end
end
