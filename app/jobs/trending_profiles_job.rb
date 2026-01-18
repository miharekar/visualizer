class TrendingProfilesJob < ApplicationJob
  queue_as :low

  WINDOW_CONFIGS = {
    "24h" => {window: 24.hours},
    "30d" => {window: 30.days}
  }.freeze

  PARSER_LABELS = {
    "decenttcl" => "Decent TCL",
    "decentjson" => "Decent JSON",
    "sepcsv" => "SEP CSV"
  }.freeze

  def perform
    WINDOW_CONFIGS.each do |window, config|
      Rails.cache.write("community/trending/#{window}", build_payload(config))
    end
  end

  private

  def build_payload(config)
    since = config.fetch(:window).ago

    public_scope = Shot.where(public: true).where(start_time: since..)
    total_scope = Shot.where(start_time: since..)

    {
      profiles: top_profiles(public_scope),
      parsers: top_parsers(public_scope),
      public_count: public_scope.count,
      total_count: total_scope.count
    }
  end

  def top_profiles(scope)
    scope
      .where.not(profile_title: [nil, ""])
      .group(Arel.sql("TRIM(profile_title)"))
      .order(Arel.sql("COUNT(*) DESC"))
      .limit(10)
      .count
      .map { |name, count| {name:, count:} }
  end

  def top_parsers(scope)
    scope
      .joins(:information)
      .group("shot_informations.brewdata->>'parser'")
      .order(Arel.sql("COUNT(*) DESC"))
      .count
      .map do |parser, count|
        parser_key = parser.to_s.split("::").last.presence || "DecentTcl"
        parser_key = parser_key.downcase
        label = PARSER_LABELS.fetch(parser_key, parser_key.titleize)
        {name: label, count:}
      end
  end
end
