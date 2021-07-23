require "test_helper"

class LoadRollbackTruncateTest < ActiveSupport::TestCase
  LogMessage = Struct.new(:message, :level, keyword_init: true)

  def setup
    @last_log = nil
    TestData.log.level = :debug
    TestData.log.writer = ->(message, level) {
      @last_log = LogMessage.new(message: message, level: level)
    }
  end

  def teardown
    TestData.log.reset
    TestData.statistics.reset
  end

  def test_loads_data_then_truncates_then_rolls_back_etc
    # Check default state
    assert_equal 0, Boop.count

    # Now load the dump
    TestData.uses_test_data
    assert_equal 15, Boop.count
    Boop.create!
    assert_equal 16, Boop.count

    # Next, truncate the boops
    TestData.uses_clean_slate
    assert_equal 0, Boop.count
    Boop.create!
    assert_equal 1, Boop.count

    # Now roll back to _just after truncate_
    TestData.uses_clean_slate
    assert_equal 0, Boop.count
    Boop.create!
    assert_equal 1, Boop.count

    # Verify default rollback works after truncate
    TestData.uses_test_data
    assert_equal 15, Boop.count

    # Verify touching non-test-data tables will also be first rollbacked when truncate is called
    TestData.uninitialize
    good = ChattyAuditLog.create!(message: "I do belong here, because now we're at the start, prior to test_data's purview")
    TestData.uses_test_data
    bad = ChattyAuditLog.create!(message: "I won't belong here after truncate because I'm data that the truncate-calling test wouldn't expect")
    assert_equal 2, ChattyAuditLog.count

    TestData.uses_clean_slate

    assert_equal 1, ChattyAuditLog.count
    refute_nil ChattyAuditLog.find_by(id: good.id)
    assert_nil ChattyAuditLog.find_by(id: bad.id)

    # Warn but load anyway if rolled back to the start and then truncated
    TestData.uninitialize
    TestData.uses_clean_slate
    assert_equal :debug, @last_log.level
    assert_match "TestData.uses_clean_slate was called, but data was not loaded. Loading data", @last_log.message
    assert_equal 0, Boop.count
    TestData.uses_test_data
    assert_equal 15, Boop.count

    # Chaos: try rolling back outside the gem (one level of extraneous rollback) and verify load recovers
    TestData.uninitialize
    TestData.statistics.reset
    assert_equal 0, TestData.statistics.load_count
    TestData.uses_test_data
    assert_equal 1, TestData.statistics.load_count
    TestData.uses_test_data # Smart enough to not load again
    assert_equal 1, TestData.statistics.load_count
    ActiveRecord::Base.connection.rollback_transaction # Someone might do this!
    TestData.uses_test_data # Still smart enough to not do this
    assert_equal 1, TestData.statistics.load_count
    TestData.uses_test_data # after load savepoint should have been healed with subsequent load call
    assert_equal 15, Boop.count

    # Chaos: try rolling back outside the gem (one level of extraneous rollback) and verify truncate recovers
    TestData.uninitialize
    TestData.statistics.reset
    assert_equal 0, TestData.statistics.truncate_count
    TestData.uses_test_data
    TestData.uses_clean_slate
    assert_equal 1, TestData.statistics.truncate_count
    TestData.uses_clean_slate
    assert_equal 1, TestData.statistics.truncate_count
    ActiveRecord::Base.connection.rollback_transaction # Someone might do this!
    TestData.uses_clean_slate # Will recover, not take the bait
    assert_equal 1, TestData.statistics.truncate_count
    TestData.uses_clean_slate # after truncate savepoint should have been healed with subsequent truncate call
    assert_equal 0, Boop.count
    TestData.uses_test_data
    assert_equal 15, Boop.count

    # Chaos: load data then call rollback two times and ensure we're still in a good spot
    TestData.uninitialize
    TestData.statistics.reset
    TestData.uses_test_data
    assert_equal 15, Boop.count
    2.times do # Two rollbacks means we're back at before_data_load
      ActiveRecord::Base.connection.rollback_transaction
    end
    assert_equal 0, Boop.count
    TestData.uses_test_data # It should successfully load again a second time
    assert_equal 15, Boop.count
    assert_equal 2, TestData.statistics.load_count

    # Chaos: truncate data then call rollback two times and ensure we're still in a good spot
    TestData.uninitialize
    TestData.statistics.reset
    TestData.uses_clean_slate # will warn-and-load and then truncate
    assert_equal 0, Boop.count
    2.times do # Two rollbacks means data is loaded but after_data_load savepoint has been lost
      ActiveRecord::Base.connection.rollback_transaction
    end
    assert_equal 15, Boop.count
    assert_equal 1, TestData.statistics.load_count
    assert_equal 1, TestData.statistics.truncate_count
    TestData.uses_clean_slate # should restore the lost after_data_load savepoint and re-truncate
    3.times do # Three rollbacks means we are at before_data_load again
      ActiveRecord::Base.connection.rollback_transaction
    end
    assert_equal 0, Boop.count
    TestData.uses_test_data
    assert_equal 15, Boop.count
    TestData.uses_clean_slate
    assert_equal 0, Boop.count
    assert_equal 3, TestData.statistics.truncate_count
    assert_equal 2, TestData.statistics.load_count
  end

  def test_suite_runs_different_tests_in_whatever_order
    # Imagine a test-datay test runs
    test_data_using_test = -> do
      TestData.uses_test_data # before each
      Boop.create!
      assert_equal 16, Boop.count
    end

    test_data_avoiding_test = -> do
      TestData.uses_clean_slate # before each
      Boop.create!
      assert_equal 1, Boop.count
    end

    # Run the tests separately:
    3.times { test_data_using_test.call }
    3.times { test_data_avoiding_test.call }

    # Mix and match the tests:
    test_data_using_test.call
    test_data_avoiding_test.call
    test_data_using_test.call
    test_data_avoiding_test.call
    test_data_using_test.call
    test_data_avoiding_test.call
  end

  def test_calling_truncate_multiple_times_will_return_you_to_truncated_state
    # In the interest of behaving similarly to .load, rollback in case the
    # previous test doesn't have an after_each as you might hope/expect
    3.times do
      TestData.uses_clean_slate
      Boop.create!
      assert_equal 1, Boop.count
    end
  end

  def test_other_rollbacks_mess_with_transaction_state_will_debug_you
    TestData.uninitialize
    TestData.statistics.reset
    TestData.uses_test_data
    ActiveRecord::Base.connection.rollback_transaction # data loaded, after_data_load save point destroyed
    TestData.uses_test_data
    assert_equal :debug, @last_log.level # debug only b/c rails fixtures will do this on every after_each if enabled
    assert_match "Recreating the :after_data_load save point", @last_log.message
    assert_equal 1, TestData.statistics.load_count

    TestData.uses_clean_slate
    ActiveRecord::Base.connection.rollback_transaction # data loaded, after_data_truncate save point destroyed
    TestData.uses_clean_slate
    assert_equal :debug, @last_log.level # debug only b/c rails fixtures will do this on every after_each if enabled
    assert_match "Recreating the :after_data_truncate save point", @last_log.message
    assert_equal 1, TestData.statistics.load_count
    assert_equal 1, TestData.statistics.truncate_count
  end
end
