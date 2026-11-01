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

    DECENT_JSON_PROFILE = JSON.parse(<<~JSON).freeze
      {"title":"Espresso/6 bar simple bloom","author":"Decent","notes":"","beverage_type":"espresso","tank_temperature":0,"target_weight":40,"target_volume":0,"target_volume_count_start":1,"version":"2",
       "steps":[
        {"exit":{"type":"pressure","value":4,"condition":"over"},"flow":8,"name":"fill","pump":"flow","sensor":"coffee","volume":0,"weight":0,"limiter":null,"seconds":20,"transition":"fast","temperature":88},
        {"exit":null,"flow":0,"name":"bloom","pump":"flow","sensor":"coffee","volume":0,"weight":5,"limiter":null,"seconds":10,"transition":"fast","temperature":85},
        {"exit":null,"name":"rise","pump":"pressure","sensor":"coffee","volume":0,"weight":0,"limiter":null,"seconds":3,"pressure":6.5,"transition":"fast","temperature":85},
        {"exit":null,"name":"hold","pump":"pressure","sensor":"coffee","volume":0,"weight":0,"limiter":{"range":2,"value":2},"seconds":120,"pressure":6.5,"transition":"fast","temperature":85}
       ]}
    JSON

    test "converts a v2 json profile without legacy fields to a tcl profile" do
      fields = json_only_information.tcl_profile_fields

      assert_equal "settings_2c", fields["settings_profile_type"]
      assert_equal 15, fields["espresso_hold_time"]
      assert_equal 88, fields["espresso_temperature"]
      assert_equal 88, fields["espresso_temperature_3"]
      assert_equal 40, fields["final_desired_shot_weight_advanced"]
      assert_equal 1, fields["final_desired_shot_volume_advanced_count_start"]
      assert_equal "en", fields["profile_language"]
      assert_nil fields["profile_to_save"]
      assert_nil fields["read_only"]
      assert fields.values_at("espresso_hold_time", "preinfusion_time", "espresso_pressure", "maximum_flow_range_default").all?(Numeric)

      blank_legacy = Parsers::Base::PROFILE_FIELDS.index_with(nil).merge("advanced_shot" => "", "json" => DECENT_JSON_PROFILE)
      [blank_legacy, {"json" => DECENT_JSON_PROFILE}].each do |profile_fields|
        assert_equal "settings_2c", ShotInformation.new(profile_fields:).tcl_profile_fields["settings_profile_type"]
      end
    end

    test "converted steps map exits and limiters" do
      steps = converted_steps

      assert_equal 4, steps.size
      assert_equal "1", steps[0]["exit_if"]
      assert_equal "pressure_over", steps[0]["exit_type"]
      assert_equal "4", steps[0]["exit_pressure_over"]
      assert_equal "0", steps[0]["pressure"]
      assert_equal "8", steps[0]["flow"]
      assert_equal %w[0 0 0], steps[1..].pluck("exit_if")
      assert_equal "2", steps[3]["max_flow_or_pressure"]
      assert_equal "2", steps[3]["max_flow_or_pressure_range"]
      assert_equal "0", steps[0]["max_flow_or_pressure"]
      assert_equal "0.6", steps[0]["max_flow_or_pressure_range"]
    end

    test "empty strings in a json profile fall back to defaults or are dropped" do
      json = DECENT_JSON_PROFILE.deep_dup.merge("target_volume_count_start" => "", "lang" => "")
      json["steps"][1]["seconds"] = ""
      json["steps"][0].merge!("pump_mode" => "pressure", "reserved" => "")
      information = ShotInformation.new(profile_fields: Parsers::Base::PROFILE_FIELDS.index_with(nil).merge("json" => json))

      assert_equal 0, information.tcl_profile_fields["final_desired_shot_volume_advanced_count_start"]
      assert_equal "en", information.tcl_profile_fields["profile_language"]
      assert_includes information.tcl_profile.lines.first, "name bloom sensor coffee pump flow transition fast temperature 85 pressure 0 flow 0 seconds 0 "
      step = tcl_list(information.tcl_profile_fields["advanced_shot"]).first.then { tcl_list(it).each_slice(2).to_h }
      assert_equal "pressure", step["pump_mode"]
      assert_not step.key?("reserved")
    end

    test "converted profile round trips through the parser" do
      body = json_only_information.tcl_profile.lines.map { "\t#{it}" }.join
      parser = Parsers::DecentTcl.new("settings {\n#{body}\n}\n").tap(&:parse)

      assert_equal "Espresso/6 bar simple bloom", parser.profile_fields["profile_title"]
      assert_equal 4, tcl_list(parser.profile_fields["advanced_shot"]).size
    end

    test "stored legacy fields win over a json profile with steps" do
      fields = Parsers::Base::PROFILE_FIELDS.index_with(nil).merge("json" => DECENT_JSON_PROFILE, "advanced_shot" => "{}", "profile_notes" => "Notes", "profile_title" => "Legacy")
      information = ShotInformation.new(profile_fields: fields)

      assert_includes information.tcl_profile.lines, "profile_title Legacy\n"
      assert_includes information.tcl_profile.lines, "advanced_shot {{}}\n"
    end

    test "ignores json profiles without usable steps" do
      [{"steps" => []}, {"steps" => ["a"]}, "junk", nil].each do |json|
        information = ShotInformation.new(profile_fields: Parsers::Base::PROFILE_FIELDS.index_with(nil).merge("json" => json))
        assert_nil information.tcl_profile_fields
        assert_not information.has_profile?
      end
    end

    test "json profile serves stored fields when the stored json is not a hash" do
      legacy = {"advanced_shot" => "{}", "profile_notes" => "Notes", "profile_title" => "Legacy"}

      [nil, "junk", ["junk"]].each do |json|
        information = ShotInformation.new(profile_fields: legacy.merge("json" => json))
        assert_equal legacy, JSON.parse(information.json_profile)
      end
    end

    test "has_profile? is true for profile hashes stored directly" do
      assert ShotInformation.new(profile_fields: {"label" => "Foo"}).has_profile?
      assert ShotInformation.new(profile_fields: {"name" => "Adaptive v1", "stages" => []}).has_profile?
      assert json_only_information.has_profile?
      assert_not ShotInformation.new(profile_fields: {}).has_profile?
    end

    private

    def json_only_information
      ShotInformation.new(profile_fields: Parsers::Base::PROFILE_FIELDS.index_with(nil).merge("json" => DECENT_JSON_PROFILE))
    end

    def converted_steps
      tcl_list(json_only_information.tcl_profile_fields["advanced_shot"]).map { tcl_list(it).each_slice(2).to_h }
    end

    def tcl_list(text)
      Parsers::DecentTcl.new("").__send__(:list_elements, text)
    end
  end
end
