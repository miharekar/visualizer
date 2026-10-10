class ConfirmationsController < ApplicationController
  skip_before_action :reject_unconfirmed_user
  skip_before_action :reject_disabled_user, only: :show
  before_action :require_authentication, only: :create
  rate_limit to: 3, within: 15.minutes, name: "confirmations-create", only: :create, by: -> { Current.user.id }, with: -> { redirect_to root_url, alert: "Try again later." }

  def show
    user = User.find_by_token_for(:email_confirmation, params[:token])
    if user
      user.confirm
      redirect_to default_path, notice: "Email confirmed. Welcome to Visualizer!"
    else
      redirect_to default_path, alert: "Confirmation link is invalid or has expired."
    end
  end

  def create
    ConfirmationsMailer.confirm(Current.user).deliver_later
    redirect_to root_url, notice: "Confirmation email sent. Check your inbox."
  end
end
