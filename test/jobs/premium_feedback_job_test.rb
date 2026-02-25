require "test_helper"

class PremiumFeedbackJobTest < ActiveJob::TestCase
  test "sends premium feedback only to cancelled users without prior cancelled premium communication" do
      eligible_user = create(:user, premium_expires_at: 4.days.ago)
      already_contacted_user = create(:user, premium_expires_at: 4.days.ago, communication: ["cancelled_premium"])
      not_eligible_yet_user = create(:user, premium_expires_at: 2.days.ago)
      premium_user = create(:user, premium_expires_at: 4.days.from_now)
      standard_user = create(:user, premium_expires_at: nil)
      supporter = create(:user, supporter: true)

      assert_enqueued_jobs 1, only: ActionMailer::MailDeliveryJob do
        PremiumFeedbackJob.perform_now
      end

      assert_equal ["cancelled_premium"], eligible_user.reload.communication
      assert_equal ["cancelled_premium"], already_contacted_user.reload.communication
      assert_equal [], not_eligible_yet_user.reload.communication
      assert_equal [], premium_user.reload.communication
      assert_equal [], standard_user.reload.communication
      assert_equal [], supporter.reload.communication
    end
end
