class PushSubscriptionsController < ApplicationController
  def create
    subscription = Current.user.push_subscriptions.find_by(push_subscription_params)
    if subscription
      subscription.touch # rubocop:disable Rails/SkipsModelValidations
    else
      Current.user.push_subscriptions.create!(push_subscription_params)
    end

    head :ok
  end

  private

  def push_subscription_params
    params.require(:push_subscription).permit(:endpoint, :p256dh_key, :auth_key).merge(user_agent: request.user_agent)
  end
end
