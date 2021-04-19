require "test_helper"

class MigratedBoopsTest < ActionDispatch::IntegrationTest
  def test_dump_includes_manually_booped_boops_plus_new_beep_column
    assert_equal 15, Boop.where(beep: true).count
  end
end
