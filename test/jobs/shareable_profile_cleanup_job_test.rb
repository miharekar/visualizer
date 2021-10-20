require "test_helper"

class ShareableProfileCleanupJobTest < ActiveJob::TestCase
  test "the truth" do
    assert ShareableProfile.count == 2
    ShareableProfileCleanupJob.perform_now
    assert ShareableProfile.count == 1
    assert_equal ShareableProfile.first, shareable_profiles(:new)
  end
end
