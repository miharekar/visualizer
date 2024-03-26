require "test_helper"

class SharedShotCleanupJobTest < ActiveJob::TestCase
  test "the truth" do
    fresh = create(:shared_shot)
    old = create(:shared_shot, :old)

    SharedShotCleanupJob.perform_now

    assert SharedShot.find_by(id: fresh.id)
    assert_not SharedShot.find_by(id: old.id)
  end
end
