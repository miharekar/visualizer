require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "self-hosted registration does not require upstream Turnstile credentials" do
    previous = ENV["VISUALIZER_SELF_HOSTED"]
    ENV["VISUALIZER_SELF_HOSTED"] = "true"

    get new_registration_url

    assert_response :success
    assert_no_match(/data-controller="turnstile"/, response.body)
  ensure
    ENV["VISUALIZER_SELF_HOSTED"] = previous
  end

  test "create uses nested form params instead of query params" do
    assert_difference ["User.count", "Session.count"], 1 do
      post registrations_url(email: "attacker@evil.com"), params: {
        user: {
          email: "victim@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    assert User.find_by(email: "victim@example.com")
    assert_nil User.find_by(email: "attacker@evil.com")
  end

  test "create registers an unconfirmed user from nested params and sends confirmation email" do
    assert_difference ["User.count", "Session.count"], 1 do
      post registrations_url, params: {
        user: {
          email: "new-user@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    assert_redirected_to root_url
    user = User.find_by!(email: "new-user@example.com")
    assert_not user.confirmed?
    assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [user]
  end
end
