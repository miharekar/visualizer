class AuthConstraint
  def self.admin?(request)
    cookies = ActionDispatch::Cookies::CookieJar.build(request, request.cookies)
    User.joins(:sessions).exists?(sessions: {id: cookies.signed[:session_id]}, admin: true)
  end
end
