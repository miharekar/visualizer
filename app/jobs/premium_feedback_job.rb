class PremiumFeedbackJob < ApplicationJob
  prepend MemoWise

  EMAILS = %w[cancelled_premium cancelled_after_trial]

  def perform(*args)
    User.where(lemon_squeezy_customer_id: ls_subscribers_trial_only.keys).find_each do |user|
      next if (user.communication & EMAILS).any?

      UserMailer.with(user:).cancelled_after_trial.deliver_later
      user.communication += ["cancelled_after_trial"]
      user.save!
    end

    User.where(premium_expires_at: ..3.days.ago).find_each do |user|
      next if (user.communication & EMAILS).any?

      UserMailer.with(user:).cancelled_premium.deliver_later
      user.communication += ["cancelled_premium"]
      user.save!
    end
  end

  private

  memo_wise def ls_subscribers
    LemonSqueezy::Client.new("/subscriptions").paginate
  end

  memo_wise def ls_subscribers_trial_only
    ls_subscribers
      .reject { |s| s.dig("attributes", "status") == "active" }
      .select do |s|
        trial_ends_at = s.dig("attributes", "trial_ends_at")&.to_time
        next unless trial_ends_at
        next unless created_at > Time.zone.at(1756684800)

        trial_ends_at < 3.days.ago
      end
      .index_by { |s| s.dig("attributes", "customer_id") }
  end
end
