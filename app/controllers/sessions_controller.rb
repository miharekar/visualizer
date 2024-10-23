class SessionsController < ApplicationController
  before_action :require_authentication, except: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: "Try again later." }

  def new; end

  def create
    user = User.authenticate_by(params.permit(:email, :password))
    if user
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_url, alert: "Try another email address or password."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_url
  end

  def omniauth_failure
    Appsignal.set_message(params[:message])
    redirect_to root_url, alert: params.values_at(:strategy, :message).join(" ").titleize
  end
end
