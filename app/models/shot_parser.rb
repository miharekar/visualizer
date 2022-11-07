# frozen_string_literal: true

class ShotParser
  attr_reader :start_time, :data, :extra, :timeframe, :profile_title, :profile_fields, :sha

  def initialize(file)
    @file = file
    parse_file
  end

  private

  def parse_file
    parsed = Parsers::Default.parse(@file)
    @data = parsed.data
    @extra = parsed.extra
    @profile_fields = parsed.profile_fields
    @profile_title = parsed.profile_title
    @start_time = parsed.start_time
    @timeframe = parsed.timeframe
    @sha = Digest::SHA256.base64digest(data.sort.to_json) if data.present?
  rescue SystemStackError, StandardError => e
    raise e unless Rails.env.production?

    Sentry.capture_exception(e, extra: {file: @file})
  end
end
