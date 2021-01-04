# frozen_string_literal: true

class ShotParser
  attr_reader :start_time, :data, :extra, :timeframe, :profile_title, :sha

  def initialize(file)
    @file = file
    @data = {}
    @extra = {}
    @start_chars_to_ignore = %i[c b]
    parse_file

    @sha = Digest::SHA256.base64digest(data.sort.to_json) if data.present?
  end

  private

  def parse_file
    parsed = Tickly::Parser.new.parse(@file)
    parsed.each do |name, data|
      extract_data_from(name, data)
      next unless name == "settings"

      data.each do |setting_name, setting_data|
        next if @start_chars_to_ignore.include?(setting_name)

        extract_data_from("setting_#{setting_name.strip}", setting_data)
      end
    end
  rescue SystemStackError # rubocop:disable Lint/SuppressedException
  end

  def extract_data_from(name, data)
    method = "extract_#{name}"
    data = @start_chars_to_ignore.include?(data.first) ? data[1..] : data
    __send__(method, data) if respond_to?(method, true)
  end

  def extract_clock(data)
    @start_time = Time.at(data.to_i).utc
  end

  def extract_espresso_elapsed(data)
    @timeframe = data
  end

  def extract_setting_profile_title(data)
    @profile_title = handle_array_string(data).force_encoding("UTF-8")
  end

  Shot::DATA_LABELS.each do |name|
    define_method("extract_#{name}") do |data|
      @data[name] = data
    end
  end

  (Shot::EXTRA_DATA + %w[DSx_bean_weight grinder_dose_weight]).each do |name|
    define_method("extract_setting_#{name}") do |data|
      @extra[name] = handle_array_string(data).force_encoding("UTF-8")
    end
  end

  def handle_array_string(data)
    return data unless data.is_a?(Array)

    if data.any? { |c| c.is_a?(Array) }
      data.map { |line| line.join(" ") }.join("\n")
    else
      data.join(" ")
    end
  end
end
