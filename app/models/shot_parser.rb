# frozen_string_literal: true

class ShotParser
  attr_reader :start_time, :data, :extra, :profile_title

  def initialize(file)
    @file = file
    @data = []
    @extra = {}
    parse_file
    @start_time = Time.at(@file[/clock (\d+)/, 1].to_i).utc
  end

  private

  def parse_file
    @file.lines.each do |line|
      extract_data(line) ||
        extract_extra(line) ||
        extract_title(line)
    end
  end

  def extract_data(line)
    match = line.match(/(?<label>\w+) \{(?<data>[\-\d. ]+)\}/)
    return unless match

    @data << {label: match[:label], data: match[:data].split}
  end

  def extract_title(line)
    match = line.match(/profile_title \{?(?<title>[^{}]+)\}?\s*?$/)
    return unless match && match[:title].present?

    @profile_title = match[:title].strip
  end

  def extract_extra(line)
    markers = %w[drink_weight bean_brand bean_type roast_date roast_level grinder_model grinder_setting drink_tds drink_ey espresso_enjoyment DSx_bean_weight grinder_dose_weight bean_weight].map do |m|
      /#{m} \{?(?<#{m}>[^{}]+)\}?\s*?$/
    end
    match = line.match(Regexp.union(markers))
    return unless match

    key, value = match.named_captures.find { |_, v| !v.nil? }
    @extra[key] = value.strip
  end
end
