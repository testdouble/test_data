require "test_helper"

class BoopsThatBoopBoopsTest < SerializedNonTransactionalTestCase
  def test_each_of_the_boops_has_a_boop
    assert_equal 15, Boop.count

    Boop.find_each do |boop|
      assert_kind_of Boop, boop.other_boop
    end
  end

  def test_it_wont_let_you_assign_a_nonsensical_boop
    assert_raise {
      Boop.last.update!(other_boop_id: 2138012)
    }
  end
end
