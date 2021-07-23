require "test_helper"

class TransactionCommittingTestCase < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    Noncommittal.stop!
    TestData.insert_test_data_dump
  end

  teardown do
    Boop.delete_all
    Noncommittal.start!
  end
end

class TransactionCommittingBoopsTest < TransactionCommittingTestCase
  i_suck_and_my_tests_are_order_dependent!

  def test_finds_the_boops
    assert_equal 15, Boop.count
  end

  def test_finds_the_boops_via_another_process
    assert_equal 15, `RAILS_ENV=test bin/rails runner "puts Boop.count"`.chomp.to_i
  end
end
