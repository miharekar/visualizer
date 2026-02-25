class PremiumFeedbackJob < ApplicationJob
  prepend MemoWise

  EMAIL = "cancelled_premium"

  def perform(*args)
    expired_users_without_feedback.find_each do |user|
      UserMailer.with(user:).cancelled_premium.deliver_later
      user.communication += [EMAIL]
      user.save!
    end
  end

  private

  def expired_users_without_feedback
    User
      .where(premium_expires_at: ..3.days.ago)
      .where.not("COALESCE(communication, '[]'::jsonb) @> :value::jsonb", value: "[\"#{EMAIL}\"]")
  end
end
