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
    user.avatar = {
      io: StringIO.new('<svg xmlns="http://www.w3.org/2000/svg"></svg>'),
      filename: "avatar.svg",
      content_type: "image/svg+xml"
    }
    user.save!(validate: false)

    assert user.reload.avatar_attachment.persisted?
    assert_not user.avatar_attachment.variable?
    assert_equal "#{user.gravatar_url}?s=64&d=mp", avatar_url(user, 64)
  end

  test "avatar URL uses the saved avatar while a new one is pending" do
    user = create(:user)
    user.avatar.attach(png_upload("saved.png"))
    saved_signed_id = user.avatar_attachment.blob.signed_id

    user.avatar = png_upload("pending.png")

    assert_includes avatar_url(user, 64), saved_signed_id
  end

  test "avatar URL falls back to Gravatar when only a new avatar is pending" do
    user = create(:user)
    user.avatar = png_upload("pending.png")

    assert_equal "#{user.gravatar_url}?s=64&d=mp", avatar_url(user, 64)
  end

  private

  def png_upload(filename)
    {io: StringIO.new("\x89PNG\r\n\x1A\n".b + SecureRandom.random_bytes(16)), filename:, content_type: "image/png"}
  end
end
