require "test_helper"

class VariableImageAttachmentTest < ActiveSupport::TestCase
  test "all image attachments reject files that cannot be transformed" do
    attachments = {
      build(:user) => :avatar,
      build(:shot) => :image,
      build(:coffee_bag) => :image,
      build(:roaster) => :image,
      Update.new(title: "Test update") => :image
    }

    attachments.each do |record, name|
      record.public_send(name).attach(
        io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
        filename: "image.svg",
        content_type: "image/svg+xml"
      )

      assert_not record.valid?, "Expected #{record.class} to reject SVG images"
      assert_includes record.errors[name], "must be a supported image"
    end
  end
end

class VariableImageAttachmentHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "avatar URL falls back to Gravatar for an invariable attachment" do
    user = create(:user)
    user.avatar.attach(
      io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
      filename: "avatar.svg",
      content_type: "image/svg+xml"
    )

    assert_equal "#{user.gravatar_url}?s=64&d=mp", avatar_url(user, 64)
  end
end
