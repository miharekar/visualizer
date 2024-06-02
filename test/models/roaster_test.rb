require "test_helper"

class RoasterTest < ActiveSupport::TestCase
  attr_reader :user

  setup do
    @user = FactoryBot.create(:user)
  end

  test ".for_user_by_name creates a new Roaster if one does not exist" do
    assert_difference "Roaster.count", 1 do
      Roaster.for_user_by_name(user, "Blue Bottle Coffee")
    end

    roaster = Roaster.last
    assert_equal "Blue Bottle Coffee", roaster.name
    assert_equal user.id, roaster.user_id
  end

  test ".for_user_by_name finds an existing Roaster if one exists" do
    roaster = user.roasters.create(name: "Blue Bottle Coffee")

    assert_no_difference "Roaster.count" do
      found_roaster = Roaster.for_user_by_name(user, "Blue Bottle Coffee")
      assert_equal roaster, found_roaster
    end
  end

  test ".for_user_by_name finds an existing Roaster if one exists case insensitive" do
    roaster = user.roasters.create(name: "Blue Bottle Coffee")

    assert_no_difference "Roaster.count" do
      found_roaster = Roaster.for_user_by_name(user, "blue bottle coffee")
      assert_equal roaster, found_roaster
    end
  end

  test ".for_user_by_name does not create a Roaster with an invalid name" do
    assert_no_difference "Roaster.count" do
      Roaster.for_user_by_name(user, "")
    end
  end
end
