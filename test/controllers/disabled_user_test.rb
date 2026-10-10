require "test_helper"

class DisabledUserTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :public)
    @shot = create(:shot, user: @user, public: true)
    @user.update!(disabled_at: Time.current)
  end

  test "signed in disabled user only sees disabled page and can sign out" do
    sign_in(@user)
    get shots_url

    assert_response :forbidden
    assert_includes response.body, "Your account has been disabled"
    assert_includes response.body, "miha@visualizer.coffee"

    delete session_url
    assert_redirected_to new_session_url
  end

  test "confirmation link re-enables unconfirmed disabled user" do
    @user.update!(confirmed_at: nil)
    sign_in(@user)
    get confirmation_url(@user.generate_token_for(:email_confirmation))

    assert_redirected_to shots_url
    assert @user.reload.confirmed?
    assert_not @user.disabled?

    get shots_url
    assert_response :success
  end

  test "confirmation link does not re-enable confirmed disabled user" do
    get confirmation_url(@user.generate_token_for(:email_confirmation))

    assert @user.reload.disabled?
  end

  test "API rejects disabled user" do
    get api_me_url, headers: {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(@user.email, "password")}, as: :json

    assert_response :forbidden
    assert_includes response.parsed_body["error"], "disabled"
  end

  test "disabling user makes profile and shots private" do
    assert_not @user.reload.public?
    assert_not @shot.reload.public?
    assert_not_includes User.visible, @user
    assert_not_includes Shot.visible, @shot

    get person_url(@user.slug)
    assert_redirected_to community_index_url

    get feed_person_url(@user.slug)
    assert_response :not_found

    get api_shots_url, as: :json
    assert_response :success
    assert_not_includes response.parsed_body["data"].pluck("id"), @shot.id

    get shot_url(@shot)
    assert_response :success

    get api_shot_url(@shot), as: :json
    assert_response :success

    code = SharedShot.create!(shot: @shot, user: @user).code
    get shared_api_shots_url(code:), as: :json
    assert_response :success

    @user.update!(public: true)
    assert_not @user.reload.public?

    @user.update!(disabled_at: nil)
    assert_not @user.disabled?
    assert_not @user.reload.public?
    assert_not @shot.reload.public?
  end

  test "emails are not delivered to disabled user" do
    @user.update!(unsubscribed_from: [])

    assert_no_emails do
      UserMailer.with(user: @user).newsletter.deliver_now
      UserMailer.with(user: @user).cancelled_premium.deliver_now
    end
  end
end
