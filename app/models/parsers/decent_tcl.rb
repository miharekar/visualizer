module Parsers
  class DecentTcl < Base
    DATA_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_state_change].freeze

    def initialize(file)
      super
      @start_chars_to_ignore = %i[c b]
    end

    def parse
      parsed = Tickly::Parser.new.parse(file)
      parsed.each do |name, data|
        extract_data_from(name, data)
        next unless name == "settings"

        data.each do |setting_name, setting_data|
          next if @start_chars_to_ignore.include?(setting_name)

          extract_data_from("setting_#{setting_name.strip}", setting_data)
        end
      end
      @profile_title = @profile_fields["profile_title"]
    rescue Tickly::Parser::Error => e
      invalid_machine = file.split("machine {")
      raise e unless invalid_machine.size > 1

      @file = invalid_machine.first
      retry
    end

    private

    DATA_LABELS.each do |name|
      define_method(:"extract_#{name}") do |data|
        @data[name] = data
      end
    end

    EXTRA_DATA_CAPTURE.each do |name|
      define_method(:"extract_setting_#{name}") do |data|
        @extra[name] = handle_array(data, smart_separator: true).force_encoding("UTF-8")
      end
    end

    PROFILE_FIELDS.each do |name|
      define_method(:"extract_setting_#{name}") do |data|
        @profile_fields[name] = handle_array(data).force_encoding("UTF-8")
      end
    end

    def extract_data_from(name, data)
      return if data.blank?

      method = "extract_#{name}"
      data = data.drop(1) if @start_chars_to_ignore.include?(data.first)
      __send__(method, data) if respond_to?(method, true)
    end

    def extract_clock(data)
      @start_time = Time.at(data.to_i).utc
    end

    def extract_espresso_elapsed(data)
      @timeframe = data
    end

    def extract_profile(data)
      stop = "#{data.last.join(" ")}\n}"
      @profile_fields["json"] = JSON.parse(file[/profile (\{(.*)#{stop})/m, 1])
    rescue StandardError
      nil
    end

    def handle_array(data, smart_separator: false)
      return data unless data.is_a?(Array)

      separator = smart_separator && data.first.is_a?(Array) ? "\n" : " "

      data.map do |line|
        next line unless line.is_a?(Array)

        line = line.map do |item|
          item.is_a?(Array) ? handle_array([item]) : item
        end

        if line.first == :b
          line.shift
          line.first.prepend("[")
          line.last.concat("]")
        end

        if line.first == :c
          line.shift
          line = [+""] if line.empty?
          line.first.prepend("{")
          line.last.concat("}")
        end

        line.join(" ")
      end.join(separator)
    end
  end
end
