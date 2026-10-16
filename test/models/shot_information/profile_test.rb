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

    test "escapes profile values that cannot be braced" do
      information = ShotInformation.new(profile_fields: {
        "advanced_shot" => "{}",
        "profile_notes" => "smile :}",
        "profile_title" => "Foo \\",
        "settings_profile_type" => "a{b"
      })

      lines = information.tcl_profile.lines
      assert_includes lines, "profile_notes smile\\ :\\}\\n\\nDownloaded\\ from\\ Visualizer\n"
      assert_includes lines, "profile_title Foo\\ \\\\\n"
      assert_includes lines, "settings_profile_type a\\{b"
    end

    test "braces or escapes whitespace-free values starting with a quote or brace" do
      information = ShotInformation.new(profile_fields: {"advanced_shot" => "{a}b", "profile_notes" => "Notes", "profile_title" => "\"foo", "settings_profile_type" => "{a"})

      lines = information.tcl_profile.lines
      assert_includes lines, "advanced_shot {{a}b}\n"
      assert_includes lines, "profile_title {\"foo}\n"
      assert_includes lines, "settings_profile_type \\{a"
    end

    test "braces whitespace-free values containing a backslash" do
      information = ShotInformation.new(profile_fields: {"advanced_shot" => "{}", "profile_notes" => "Notes", "profile_title" => "a\\x;", "settings_profile_type" => "\\}"})

      lines = information.tcl_profile.lines
      assert_includes lines, "profile_title {a\\x;}\n"
      assert_includes lines, "settings_profile_type {\\}}"

      body = lines.map { "\t#{it}" }.join
      parser = Parsers::DecentTcl.new("settings {\n#{body}\n}\n").tap(&:parse)
      assert_equal "a\\x;", parser.profile_fields["profile_title"]
      assert_equal "\\}", parser.profile_fields["settings_profile_type"]
    end

    test "exports numeric profile values" do
      information = ShotInformation.new(profile_fields: {"advanced_shot" => "{}", "profile_notes" => "Notes", "espresso_temperature" => 92, "espresso_temperature_0" => 88.5})

      lines = information.tcl_profile.lines
      assert_includes lines, "espresso_temperature 92\n"
      assert_includes lines, "espresso_temperature_0 88.5\n"
    end

    test "keeps braces around balanced values with escaped braces" do
      information = ShotInformation.new(profile_fields: {"advanced_shot" => "{}", "profile_notes" => "Notes", "profile_title" => "a\\{b c"})

      assert_includes information.tcl_profile.lines, "profile_title {a\\{b c}"
    end

    test "escaped profile round trips through the parser" do
      information = ShotInformation.new(profile_fields: {"advanced_shot" => "{}", "profile_notes" => "smile :}", "profile_title" => "Foo \\"})

      body = information.tcl_profile.lines.map { "\t#{it}" }.join
      parser = Parsers::DecentTcl.new("settings {\n#{body}\n}\n").tap(&:parse)
      assert_equal "Foo \\", parser.profile_fields["profile_title"]
      assert_equal "smile :}\n\nDownloaded from Visualizer", parser.profile_fields["profile_notes"]
    end
  end
end
