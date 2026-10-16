require "test_helper"

module Oauth
  class ApplicationsControllerTest < ActionDispatch::IntegrationTest
    setup do
      host! "example.com"
      @user = create(:user, developer: true)
      sign_in(@user)
    end

    test "create shows the client secret once" do
      post oauth_applications_url, params: {doorkeeper_application: {name: "Test App", redirect_uri: "https://example.com/callback", scopes: "read"}}

      application = @user.oauth_applications.sole
      assert_redirected_to oauth_application_url(application)

      follow_redirect!

      secret = css_select("#secret").text.strip
      assert secret.present?
      assert_equal application, Doorkeeper::Application.by_uid_and_secret(application.uid, secret)

      get oauth_application_url(application)

      assert_not_includes response.body, secret
    end
  end
end
