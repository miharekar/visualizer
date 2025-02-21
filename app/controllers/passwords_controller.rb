class PasswordsController < ApplicationController
  before_action :set_user_by_token, only: %i[edit update]

  def new; end

  def edit; end

  def create
    user = User.find_by(email: params[:email])
    PasswordsMailer.reset(user).deliver_later if user

    redirect_to new_session_url, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      redirect_to new_session_url, notice: "Password has been reset."
    else
      redirect_to edit_password_url(params[:token]), alert: @user.errors.full_messages.join(", ")
    end
  end

  private

  def set_user_by_token
    @user = User.find_by_password_reset_token!(params[:token]) # rubocop:disable Rails/DynamicFindBy
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_password_url, alert: "Password reset link is invalid or has expired."
  end
end
