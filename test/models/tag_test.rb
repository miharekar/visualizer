require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "generates slug from name" do
    user = create(:user)
    tag = create(:tag, name: "My Tag", user:)
    assert_equal "my-tag", tag.slug
  end

  test "generates unique slug within user scope" do
    user_1 = create(:user)
    user_2 = create(:user)

    tag_1 = create(:tag, name: "My Tag", user: user_1)
    tag_2 = create(:tag, name: "My Tag", user: user_1)
    tag_3 = create(:tag, name: "My Tag", user: user_2)

    assert_equal "my-tag", tag_1.slug
    assert_equal "my-tag-2", tag_2.slug
    assert_equal "my-tag", tag_3.slug
  end

  test "keeps existing slug" do
    user = create(:user)
    tag = create(:tag, name: "My Tag", slug: "custom-slug", user:)
    assert_equal "custom-slug", tag.slug
  end

  test "validates uniqueness of slug scoped to user" do
    user = create(:user)
    create(:tag, name: "My Tag", slug: "my-tag", user:)

    tag = build(:tag, name: "My Tag", slug: "my-tag", user:)
    assert_not tag.valid?
    assert_includes tag.errors[:slug], "has already been taken"
  end
end
