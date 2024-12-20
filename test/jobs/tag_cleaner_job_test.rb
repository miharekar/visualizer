require "test_helper"

class TagCleanerJobTest < ActiveJob::TestCase
  test "deletes tags with no shots and keeps tags with shots" do
    user_one = create(:user)
    user_two = create(:user)

    unused_tag_one = create(:tag, name: "Unused Tag 1", user: user_one)
    used_tag_one = create(:tag, name: "Used Tag 1", user: user_one)
    shot_one = create(:shot, user: user_one)
    shot_one.tags << used_tag_one

    unused_tag_two = create(:tag, name: "Unused Tag 2", user: user_two)
    used_tag_two = create(:tag, name: "Used Tag 2", user: user_two)
    shot_two = create(:shot, user: user_two)
    shot_two.tags << used_tag_two

    assert_difference "Tag.count", -2 do
      TagCleanerJob.perform_now
    end

    assert_nil Tag.find_by(id: unused_tag_one.id)
    assert Tag.find_by(id: used_tag_one.id)

    assert_nil Tag.find_by(id: unused_tag_two.id)
    assert Tag.find_by(id: used_tag_two.id)
  end
end
