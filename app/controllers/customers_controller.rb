class CustomersController < ApplicationController
  before_action :require_authentication
  before_action :check_admin!

  def index
    @customers = Customer.order(amount: :desc).includes(:user, :subscriptions)
  end
end
