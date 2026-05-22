require "test_helper"

class UserMailerTest < ActionMailer::TestCase
  test "shot uploaded email includes one click unsubscribe headers" do
    user = create(:user, :premium, unsubscribed_from: [])
    shot = create(:shot, user:, profile_title: "Blooming Espresso")

    email = UserMailer.with(user:, shot:).shot_uploaded

    assert_equal [user.email], email.to
    assert_equal "See your new Blooming Espresso shot 👀", email.subject
    assert_includes email["List-Unsubscribe"].to_s, "/emails/unsubscribe?token="
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].to_s
    assert_includes email.body.to_s, "/shots/#{shot.id}"
  end
end
