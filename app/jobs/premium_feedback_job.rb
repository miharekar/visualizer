class PremiumFeedbackJob < ApplicationJob
  prepend MemoWise

  CUT_OFF_TIME = Time.zone.at(1756684800)
  EMAILS = %w[cancelled_premium cancelled_after_trial]

  def perform(*args)
    User.where(premium_expires_at: ..3.days.ago).find_each do |user|
      next if (user.communication & EMAILS).any?

      UserMailer.with(user:).cancelled_premium.deliver_later
      user.communication += ["cancelled_premium"]
      user.save!
    end
  end
end
