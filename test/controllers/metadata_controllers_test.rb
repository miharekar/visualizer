require "test_helper"

class MetadataControllersTest < ActionDispatch::IntegrationTest
  test "premium users add and remove custom fields" do
    user = create(:user, :premium)
    sign_in(user)

    post shot_metadata_url(field: "Basket")
    post coffee_bag_metadata_url(field: "Color")
    assert_equal ["Basket"], user.reload.shot_metadata_fields
    assert_equal ["Color"], user.coffee_bag_metadata_fields

    delete shot_metadata_url(field: "Basket")
    assert_empty user.reload.shot_metadata_fields
  end

  test "non-premium users cannot add custom fields" do
    user = create(:user)
    sign_in(user)

    post shot_metadata_url(field: "Basket")
    assert_redirected_to premium_index_path
    post coffee_bag_metadata_url(field: "Color")
    assert_redirected_to premium_index_path

    user.reload
    assert_empty user.shot_metadata_fields
    assert_empty user.coffee_bag_metadata_fields
  end

  test "non-premium users cannot remove custom fields" do
    user = create(:user, :with_shot_metadata, :with_coffee_bag_metadata)
    sign_in(user)

    delete shot_metadata_url(field: "Bean variety")
    delete coffee_bag_metadata_url(field: "Bean color")

    user.reload
    assert_includes user.shot_metadata_fields, "Bean variety"
    assert_includes user.coffee_bag_metadata_fields, "Bean color"
  end
end
