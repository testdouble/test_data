require "test_helper"

class TestDataTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::TestData::VERSION
  end
end
