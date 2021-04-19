require "test_helper"

class BasicBoopsTest < ActionDispatch::IntegrationTest
  i_suck_and_my_tests_are_order_dependent!

  def test_contains_initially_seeded_boops
    assert_equal 10, Boop.count
  end

  def test_adds_some_boops
    3.times { Boop.create! }
    assert_equal 13, Boop.count
  end

  def test_back_to_the_original_number_of_seeded_boops
    assert_equal 10, Boop.count
  end
end
