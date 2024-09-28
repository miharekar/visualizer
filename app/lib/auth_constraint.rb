class AuthConstraint
  def self.admin?(request)
    cookies = ActionDispatch::Cookies::CookieJar.build(request, request.cookies)
    User.joins(:sessions).where(sessions: {id: cookies.signed[:session_id]}, admin: true).exists?
  end
end
