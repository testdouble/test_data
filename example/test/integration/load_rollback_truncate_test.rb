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
    TestData.rollback(:before_data_load)
  end

  def test_loads_data_then_truncates_then_rolls_back_etc
    # Check default state
    assert_equal 0, Boop.count

    # Now load the dump
    TestData.load
    assert_equal 15, Boop.count
    Boop.create!
    assert_equal 16, Boop.count

    # Next, truncate the boops
    TestData.truncate
    assert_equal 0, Boop.count
    Boop.create!
    assert_equal 1, Boop.count

    # Now roll back to _just after truncate_
    TestData.rollback(:after_data_truncate)
    assert_equal 0, Boop.count
    Boop.create!
    assert_equal 1, Boop.count

    # Verify default rollback works after truncate
    TestData.rollback
    assert_equal 15, Boop.count

    # Verify touching non-test-data tables will also be first rollbacked when truncate is called
    TestData.rollback(:before_data_load)
    good = ChattyAuditLog.create!(message: "I do belong here, because now we're at the start, prior to test_data's purview")
    TestData.load
    bad = ChattyAuditLog.create!(message: "I won't belong here after truncate because I'm data that the truncate-calling test wouldn't expect")
    assert_equal 2, ChattyAuditLog.count

    TestData.truncate

    assert_equal 1, ChattyAuditLog.count
    refute_nil ChattyAuditLog.find_by(id: good.id)
    assert_nil ChattyAuditLog.find_by(id: bad.id)

    # Verify rollbacking to some nonsense savepoint errors out:
    error = assert_raise(TestData::Error) { TestData.rollback(:before_nonsense) }
    assert_match "No known save point named 'before_nonsense'", error.message

    # Warn but load anyway if rolled back to the start and then truncated
    TestData.rollback(:before_data_load)
    TestData.truncate
    assert_equal :warn, @last_log.level
    assert_match "TestData.truncate was called, but data was not loaded. Loading data", @last_log.message
    assert_equal 0, Boop.count
    TestData.rollback
    assert_equal 15, Boop.count

    # Chaos: try rolling back outside the gem (one level of extraneous rollback) and verify load recovers
    TestData.rollback(:before_data_load)
    TestData.statistics.reset
    assert_equal 0, TestData.statistics.load_count
    TestData.load
    assert_equal 1, TestData.statistics.load_count
    TestData.load # Smart enough to not load again
    assert_equal 1, TestData.statistics.load_count
    ActiveRecord::Base.connection.rollback_transaction # Someone might do this!
    TestData.load # Still smart enough to not do this
    assert_equal 1, TestData.statistics.load_count
    TestData.rollback # after load savepoint should have been healed with subsequent load call
    assert_equal 15, Boop.count

    # Chaos: try rolling back outside the gem (one level of extraneous rollback) and verify truncate recovers
    TestData.rollback(:before_data_load)
    TestData.statistics.reset
    assert_equal 0, TestData.statistics.truncate_count
    TestData.load
    TestData.truncate
    assert_equal 1, TestData.statistics.truncate_count
    TestData.truncate
    assert_equal 1, TestData.statistics.truncate_count
    ActiveRecord::Base.connection.rollback_transaction # Someone might do this!
    TestData.truncate # Will recover, not take the bait
    assert_equal 1, TestData.statistics.truncate_count
    TestData.rollback(:after_data_truncate) # after truncate savepoint should have been healed with subsequent truncate call
    assert_equal 0, Boop.count
    TestData.rollback
    assert_equal 15, Boop.count

    # Chaos: load data then call rollback two times and ensure we're still in a good spot
    TestData.rollback(:before_data_load)
    TestData.statistics.reset
    TestData.load
    assert_equal 15, Boop.count
    2.times do # Two rollbacks means we're back at before_data_load
      ActiveRecord::Base.connection.rollback_transaction
    end
    assert_equal 0, Boop.count
    TestData.load # It should successfully load again a second time
    assert_equal 15, Boop.count
    assert_equal 2, TestData.statistics.load_count

    # Chaos: truncate data then call rollback two times and ensure we're still in a good spot
    TestData.rollback(:before_data_load)
    TestData.statistics.reset
    TestData.truncate # will warn-and-load and then truncate
    assert_equal 0, Boop.count
    2.times do # Two rollbacks means data is loaded but after_data_load savepoint has been lost
      ActiveRecord::Base.connection.rollback_transaction
    end
    assert_equal 15, Boop.count
    assert_equal 1, TestData.statistics.load_count
    assert_equal 1, TestData.statistics.truncate_count
    TestData.truncate # should restore the lost after_data_load savepoint and re-truncate
    3.times do # Three rollbacks means we are at before_data_load again
      ActiveRecord::Base.connection.rollback_transaction
    end
    assert_equal 0, Boop.count
    TestData.load
    assert_equal 15, Boop.count
    TestData.truncate
    assert_equal 0, Boop.count
    assert_equal 3, TestData.statistics.truncate_count
    assert_equal 2, TestData.statistics.load_count
  end

  def test_suite_runs_different_tests_in_whatever_order
    # Imagine a test-datay test runs
    test_data_using_test = -> do
      TestData.load # before each
      Boop.create!
      assert_equal 16, Boop.count
      TestData.rollback # after each
    end

    test_data_avoiding_test = -> do
      TestData.truncate # before each
      Boop.create!
      assert_equal 1, Boop.count
      TestData.rollback(:after_data_truncate) # after each
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
      TestData.truncate
      Boop.create!
      assert_equal 1, Boop.count
    end
  end

  def test_other_rollbacks_mess_with_transaction_state_will_debug_you
    TestData.load
    ActiveRecord::Base.connection.rollback_transaction # data loaded, after_data_load save point destroyed
    TestData.load
    assert_equal :debug, @last_log.level # debug only b/c rails fixtures will do this on every after_each if enabled
    assert_match "Recreating the :after_data_load save point", @last_log.message
    assert_equal 1, TestData.statistics.load_count

    TestData.truncate
    ActiveRecord::Base.connection.rollback_transaction # data loaded, after_data_truncate save point destroyed
    TestData.truncate
    assert_equal :debug, @last_log.level # debug only b/c rails fixtures will do this on every after_each if enabled
    assert_match "Recreating the :after_data_truncate save point", @last_log.message
    assert_equal 1, TestData.statistics.load_count
    assert_equal 1, TestData.statistics.truncate_count
  end
end
