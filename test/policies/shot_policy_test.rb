require "test_helper"

class ShotPolicyTest < ActiveSupport::TestCase
  test "update allows owner" do
    user = create(:user)
    shot = create(:shot, user:)

    assert ShotPolicy.new(shot, user:).apply(:update?)
  end

  test "update rejects non-owner" do
    shot = create(:shot)

    assert_not ShotPolicy.new(shot, user: create(:user)).apply(:update?)
  end

  test "show allows guest" do
    assert ShotPolicy.new(create(:shot), user: nil).apply(:show?)
  end
end
