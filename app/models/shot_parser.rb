# frozen_string_literal: true

class ShotParser
  attr_reader :start_time, :data, :profile_title

  def initialize(file)
    @file = file
    @data = parsed_file
    @start_time = Time.at(@file[/clock (\d+)/, 1].to_i).utc
  end

  private

  def parsed_file
    @file.lines.map do |line|
      match = line.match(/(?<label>\w+) \{(?<data>[\-\d. ]+)\}|profile_title \{(?<title>.+)\}/)
      next unless match

      if match[:title].present?
        @profile_title = match[:title]
        next
      end

      {label: match[:label], data: match[:data].split(" ").map { |v| v == "-1.0" ? nil : v }}
    end.compact
  end
end
