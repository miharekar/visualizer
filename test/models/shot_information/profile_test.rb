require "test_helper"

class ShotInformation
  class ProfileTest < ActiveSupport::TestCase
    test "braces profile values containing whitespace" do
      information = ShotInformation.new(profile_fields: {
        "advanced_shot" => "{}",
        "profile_notes" => "Notes",
        "profile_title" => "D-Flow / Q",
        "settings_profile_type" => "settings_2c"
      })

      assert_includes information.tcl_profile.lines, "profile_title {D-Flow / Q}\n"
      assert_includes information.tcl_profile.lines, "settings_profile_type settings_2c"
    end
  end
end
