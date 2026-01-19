module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    before_action :tag_request
    helper_method :authenticated?
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    return if cookies.signed[:session_id].blank?

    Session.find_by(id: cookies.signed[:session_id])
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_url
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || shots_url
  end

  def start_new_session_for(user)
    user.sessions.find_or_create_by!(user_agent: request.user_agent, ip_address: request.headers["CF-Connecting-IP"]).tap do
      Current.session = it
      cookies.signed.permanent[:session_id] = {value: it.id, httponly: true, same_site: :lax}
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end

  def tag_request
    Appsignal.add_tags(email: Current.user&.email, user_id: Current.user&.id, remote_ip: request.remote_ip, cloudflare_ip: request.headers["CF-Connecting-IP"], hetzner_lb: request.headers["X-Forwarded-For"])
  end
end
