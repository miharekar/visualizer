require "test_helper"

class UnconfirmedUserCleanupJobTest < ActiveJob::TestCase
  test "destroys users unconfirmed for over 7 days" do
    stale = create(:user, :unconfirmed, created_at: 8.days.ago)
    fresh = create(:user, :unconfirmed, created_at: 6.days.ago)
    confirmed = create(:user, created_at: 8.days.ago)

    UnconfirmedUserCleanupJob.perform_now

    assert_not User.exists?(stale.id)
    assert User.exists?(fresh.id)
    assert User.exists?(confirmed.id)
  end
end
