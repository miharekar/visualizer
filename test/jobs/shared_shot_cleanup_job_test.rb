# frozen_string_literal: true

require "test_helper"

class SharedShotCleanupJobTest < ActiveJob::TestCase
  test "the truth" do
    assert SharedShot.count == 2
    SharedShotCleanupJob.perform_now
    assert SharedShot.count == 1
    assert_equal SharedShot.first, shared_shots(:new)
  end
end
