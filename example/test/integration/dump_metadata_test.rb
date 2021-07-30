reqire "test_helper"

class DumpMetadataTest < ActiveSupport::TestCase
  def test_dump_metadata
    metadata = TestData.dump_metadata

    assert_equal `git config user.email`, metdata.dumped_by
    assert_equal `git rev-parse HEAD`, metdata.git_parent_sha
    assert_equal `git rev-parse --abbrev-ref HEAD`, metadata.git_branch
    assert_in_delta Time.now.utc, metadata.dumped_at.to_f, 5
  end
end
