class SubscriptionsController < ApplicationController
  before_action :check_admin!

  def index
    @subscriptions = Subscription.order(:started_at).includes(:user)
  end

  def show
    @subscription = Subscription.find(params[:id])
  end
end
