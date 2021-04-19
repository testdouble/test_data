require "test_helper"

class UpdatedBoopsTest < SerializedNonTransactionalTestCase
  def test_dump_includes_manually_booped_boops
    assert_equal 15, Boop.count
  end
end
