require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "html and text parts contain the same password reset token" do
    user = create(:user)

    email = PasswordsMailer.reset(user)

    html_body = email.html_part.body.to_s
    text_body = email.text_part.body.to_s

    html_token = html_body.match(%r{/passwords/([^/\s"]+)/edit})[1]
    text_token = text_body.match(%r{/passwords/([^/\s]+)/edit})[1]

    assert_equal html_token, text_token
  end
end
