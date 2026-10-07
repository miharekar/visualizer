require "test_helper"

class UnconfirmedUserTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :unconfirmed)
  end

  test "signed in unconfirmed user only sees confirmation page, can resend and sign out" do
    sign_in(@user)
    get shots_url

    assert_response :forbidden
    assert_includes response.body, "Confirm your email"
    assert_includes response.body, @user.email

    assert_enqueued_email_with ConfirmationsMailer, :confirm, args: [@user] do
      post confirmations_url
    end
    assert_redirected_to root_url

    delete session_url
    assert_redirected_to new_session_url
  end

  test "confirmation link confirms user" do
    sign_in(@user)
    get confirmation_url(@user.generate_token_for(:email_confirmation))

    assert_redirected_to shots_url
    assert @user.reload.confirmed?

    get shots_url
    assert_response :success
  end

  test "invalid confirmation link does not confirm user" do
    get confirmation_url("invalid")

    assert_redirected_to community_index_url
    assert_not @user.reload.confirmed?
  end

  test "API rejects unconfirmed user" do
    get api_me_url, headers: {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, "password")}, as: :json

    assert_response :forbidden
    assert_includes response.parsed_body["error"], "Confirm your email"
  end

  test "only confirmation emails are delivered to unconfirmed user" do
    @user.update!(unsubscribed_from: [])

    assert_no_emails do
      UserMailer.with(user: @user).newsletter.deliver_now
    end

    assert_emails 1 do
      ConfirmationsMailer.confirm(@user).deliver_now
    end
  end
end
