module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?
  end

  private

  def authenticated?
    Current.session.present?
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    find_session_by_cookie || find_devise_session
  end

  def find_session_by_cookie
    Current.session = Session.find_by(id: cookies.signed[:session_id])
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_url
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = {value: session.id, httponly: true, same_site: :lax}
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end

  # Migrate Devise users over. Remove at some point.

  def find_devise_session
    return unless devise_info

    clear_devise_info
    start_new_session_for(devise_user) if devise_user
  end

  def devise_info
    @devise_info ||= session["warden.user.user.key"].presence || cookies.signed["remember_user_token"].presence
  end

  def devise_user
    @devise_user ||= begin
      user_id = devise_info.dig(0, 0)
      user_salt = devise_info.dig(1)
      return if user_id.blank? || user_salt.blank?

      user = User.find_by(id: user_id)
      user if user&.password_digest[0, 29] == user_salt
    end
  end

  def clear_devise_info
    session.delete("warden.user.user.key")
    cookies.delete("remember_user_token")
  end
end
