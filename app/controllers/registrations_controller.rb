class RegistrationsController < ApplicationController
  include Turnstile

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if verify_turnstile && @user.save
      start_new_session_for(@user)
      redirect_to root_path, notice: "Welcome to the Visualizer!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:email, :password, :password_confirmation)
  end
end
