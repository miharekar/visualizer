class PushSubscriptionsController < ApplicationController
  def create
    subscription = Current.user.push_subscriptions.find_by(push_subscription_params)
    if subscription
      subscription.update!(user_agent: request.user_agent)
    else
      Current.user.push_subscriptions.create!(push_subscription_params.merge(user_agent: request.user_agent))
    end

    head :ok
  end

  private

  def push_subscription_params
    params.expect(push_subscription: %i[endpoint p256dh_key auth_key])
  end
end
