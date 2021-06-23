require "test_helper"

TestData.config.use_transactional_data_loader = false

class TransactionCommittingTestCase < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    Noncommittal.stop!
    TestData.load
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

  def test_cant_have_it_both_ways
    error = assert_raise(TestData::Error) do
      TestData.config.use_transactional_data_loader = true
    end
    assert_match "There is already a non-transactional data loader", error.message
  end
end
