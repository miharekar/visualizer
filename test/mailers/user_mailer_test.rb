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

  test "newsletter includes announcement absolute URLs and broadcast unsubscribe headers" do
    user = create(:user)
    email = UserMailer.with(user:).newsletter
    document = Nokogiri::HTML5(email.body.decoded)

    assert_equal [user.email], email.to
    assert_equal "Is this Visualizer v5?", email.subject
    assert_equal "broadcast", email[:message_stream].value
    assert_includes email["List-Unsubscribe"].to_s, "/emails/unsubscribe?token="
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].to_s
    assert_equal ["Journal.", "Create shots.", "Instant Filters for everyone."], document.css("p > strong").map(&:text)
    assert document.at_css("a[href='https://visualizer.test/updates/bending-the-tables']")
    assert document.at_css("a[href='https://visualizer.test/profile/edit']")
    assert document.at_css("a[href='https://visualizer.test/premium#journal']")
    assert_match %r{\Ahttps://visualizer\.test/assets/premium/journal.*\.png\z}, document.at_css("img[alt^='Journal']")["src"]
    assert_empty document.css("a[href^='/'], img[src^='/']")
  end

  test "newsletter is not delivered to opted out users" do
    user = create(:user, unsubscribed_from: ["newsletter"])

    assert_no_emails do
      perform_enqueued_jobs do
        UserMailer.with(user:).newsletter.deliver_later
      end
    end
  end
end
