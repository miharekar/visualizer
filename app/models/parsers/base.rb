module Parsers
  class Base
    prepend MemoWise
    include Bsearch

    PROFILE_FIELDS = %w[advanced_shot author beverage_type espresso_decline_time espresso_hold_time espresso_pressure espresso_temperature espresso_temperature_0 espresso_temperature_1 espresso_temperature_2 espresso_temperature_3 espresso_temperature_steps_enabled final_desired_shot_volume final_desired_shot_volume_advanced final_desired_shot_volume_advanced_count_start final_desired_shot_weight final_desired_shot_weight_advanced flow_profile_decline flow_profile_decline_time flow_profile_hold flow_profile_hold_time flow_profile_minimum_pressure flow_profile_preinfusion flow_profile_preinfusion_time maximum_flow maximum_flow_range maximum_flow_range_advanced maximum_flow_range_default maximum_pressure maximum_pressure_range maximum_pressure_range_advanced maximum_pressure_range_default original_profile_title preinfusion_flow_rate preinfusion_guarantee preinfusion_stop_pressure preinfusion_time pressure_end profile_filename profile_language profile_notes profile_title profile_to_save settings_profile_type tank_desired_water_temperature].freeze
    EXTRA_DATA_METHODS = %w[drink_weight grinder_model grinder_setting bean_brand bean_type roast_level roast_date drink_tds drink_ey espresso_enjoyment espresso_notes bean_notes].freeze
    EXTRA_DATA_CAPTURE = (EXTRA_DATA_METHODS + %w[bean_weight DSx_bean_weight grinder_dose_weight enable_fahrenheit my_name skin]).freeze

    attr_reader :file, :json, :start_time, :data, :extra, :brewdata, :timeframe, :profile_title, :profile_fields, :json

    def self.parser_for(file)
      if file.start_with?("{")
        json = parse_json(file)
        if json.key?("mill") || json.key?("brewFlow")
          Beanconqueror.new(file, json)
        else
          DecentJson.new(file, json)
        end
      elsif file.start_with?("clock", "sequence_id", "filename")
        DecentTcl.new(file)
      elsif file.start_with?("information_type")
        SepCsv.new(file)
      else
        new(file)
      end
    end

    def self.parse_json(file)
      Oj.safe_load(file)
    end

    def initialize(file, json = nil)
      @file = file
      @json = json
      @data = {}
      @extra = {}
      @profile_fields = {}
      @brewdata = {}
    end

    def build_shot(user)
      parse

      shot = existing_shot(user) || Shot.find_or_initialize_by(user:, sha:)

      shot.profile_title = profile_title
      shot.start_time = start_time
      shot.public = user.public
      set_information(shot)
      set_coffee_bag(shot)

      if shot.valid?
        extract_fields_from_extra(shot)
        shot.duration = calculate_duration
        shot.information.save if shot.information.persisted?
      elsif file.start_with?("advanced_shot")
        shot.errors.add(:base, :profile_file, message: "This is a profile file, not a shot file")
      elsif Rails.env.production? && shot.errors.reject { |e| e.type == :over_daily_limit }.any?
        s3_response = Aws::S3::Client.new.put_object(acl: "private", body: file, bucket: "visualizer-coffee", key: "debug/#{Time.current.iso8601}.json")
        Appsignal.set_message("Something is wrong with this file #{s3_response.etag} | #{shot.errors.full_messages.join(", ")}")
      end
      shot
    end

    def parse
      nil
    rescue SystemStackError, StandardError => e
      Rails.env.development? ? raise(e) : new(file)
    end

    private

    memo_wise def sha
      Digest::SHA256.base64digest(data.sort.to_json) if data.present?
    end

    def existing_shot(user)
      nil
    end

    def set_information(shot)
      shot.information ||= shot.build_information
      shot.information.data = data
      shot.information.extra = extra
      shot.information.timeframe = timeframe
      shot.information.profile_fields = profile_fields
      shot.information.brewdata = brewdata
      shot.information.brewdata["parser"] = self.class.name
    end

    def set_coffee_bag(shot)
      if shot.user.coffee_management_enabled?
        roaster = Roaster.for_user_by_name(shot.user, extra["bean_brand"])
        shot.coffee_bag = CoffeeBag.for_roaster_by_name_and_date(roaster, extra["bean_type"], extra["roast_date"], roast_level: extra["roast_level"])
        set_coffee_bag_attributes(shot)
      else
        shot.coffee_bag = nil
      end
    end

    def set_coffee_bag_attributes(shot)
      nil
    end

    def calculate_duration
      index = if data["espresso_flow"]
        [data["espresso_flow"].size, timeframe.size].min
      else
        timeframe.size
      end
      timeframe[index - 1].to_f
    end

    def extract_fields_from_extra(shot)
      EXTRA_DATA_METHODS.each do |attr|
        shot.public_send(:"#{attr}=", extra[attr].presence)
      end
      shot.bean_weight = extra.slice("DSx_bean_weight", "grinder_dose_weight", "bean_weight").values.find { |v| v.to_i.positive? }
      shot.barista = extra["my_name"].presence
    end
  end
end
