require "test_helper"

class ShotTest < ActiveSupport::TestCase
  test "can have multiple tags" do
    user = create(:user)
    shot = create(:shot, user:)
    tag_1 = create(:tag, name: "Light roast", user:)
    tag_2 = create(:tag, name: "Ethiopia", user:)

    shot.tags << tag_1
    shot.tags << tag_2

    assert_equal 2, shot.tags.count
    assert_includes shot.tags, tag_1
    assert_includes shot.tags, tag_2
  end

  test "cannot have the same tag twice" do
    user = create(:user)
    shot = create(:shot, user:)
    tag = create(:tag, name: "Light roast", user:)

    shot.tags << tag
    assert_raises(ActiveRecord::RecordInvalid) do
      shot.tags << tag
    end

    assert_equal 1, shot.tags.count
  end

  test "can remove tags" do
    user = create(:user)
    shot = create(:shot, user:)
    tag = create(:tag, name: "Light roast", user:)

    shot.tags << tag
    assert_equal 1, shot.tags.count

    shot.tags.delete(tag)
    assert_equal 0, shot.tags.count
  end
end
