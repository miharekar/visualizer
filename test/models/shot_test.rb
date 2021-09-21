require "test_helper"

class ShotTest < ActiveSupport::TestCase
  test "extracts the non-zero bean weight" do
    shot = Shot.from_file(users(:miha), "test/fixtures/files/dsx_weight.shot")
    assert_equal 18.0, shot.bean_weight.to_f
  end
end
