class RegistrationsController < ApplicationController
  include Turnstile

  rate_limit to: 10, within: 3.minutes, name: "registrations-create", only: :create, with: -> { redirect_to new_registration_url, alert: "Try again later." }

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if verify_turnstile
      if @user.save
        start_new_session_for(@user)
        ConfirmationsMailer.confirm(@user).deliver_later
        return redirect_to root_path, notice: "Welcome to Visualizer! Check your email to confirm your account."
      end
    else
      flash.now[:alert] = "Human verification failed - make sure you're not a robot!"
    end
    render :new, status: :unprocessable_content
  end

  private

  def user_params
    params.expect(user: %i[email password password_confirmation])
  end
end
