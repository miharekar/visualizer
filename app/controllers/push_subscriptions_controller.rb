class PushSubscriptionsController < ApplicationController
  rescue_from(ActiveRecord::RecordInvalid) { head :unprocessable_content }

  def create
    subscription = Current.user.push_subscriptions.find_by(push_subscription_params)
    if subscription
      subscription.update!(user_agent: request.user_agent, updated_at: Time.current)
    else
      Current.user.push_subscriptions.create!(push_subscription_params.merge(user_agent: request.user_agent))
    end
    Current.user.push_subscriptions.order(updated_at: :desc).offset(10).destroy_all

    head :ok
  end

  private

  def push_subscription_params
    params.expect(push_subscription: %i[endpoint p256dh_key auth_key])
  end
end
