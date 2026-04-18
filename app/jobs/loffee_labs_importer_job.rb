class LoffeeLabsImporterJob < ApplicationJob
  retry_on TypeError, wait: :polynomially_longer

  queue_as :low

  BASE_URL = "https://beta.loffeelabs.com/api/v2".freeze
  ROASTERS_URL = "#{BASE_URL}/terms?list=roasters".freeze
  BEANS_BULK_URL = "#{BASE_URL}/beans/bulk".freeze

  COFFEE_BAG_JSON_MAPPING = {
    name: "roast-name",
    url: "link",
    country: "origin",
    region: "region",
    elevation: "elevation",
    farmer: "producer",
    harvest_time: "harvest",
    processing: "process",
    roast_level: "degree",
    variety: "variety",
    tasting_notes: "tasting"
  }.freeze

  EXCLUDED_URLS_REGEX = Regexp.union(%w[airworkscoffee.com thebeanarchives.com mystery.coffee])

  def perform(cut_off: 3.months.ago)
    @cut_off = cut_off
    @roasters = {}
    import_roasters
    import_beans
  end

  private

  def import_roasters
    JSON.parse(SimpleDownloader.new(ROASTERS_URL).body).fetch("data", []).each do |name|
      name = name&.squish
      next if name.blank?

      @roasters[name] = CanonicalRoaster.find_or_create_by!(loffee_labs_id: name) { |roaster| roaster.name = name }
    end
  end

  def import_beans
    json = JSON.parse(SimpleDownloader.new(BEANS_BULK_URL, headers: {"Authorization" => "Bearer #{Rails.application.credentials.dig(:loffee_labs, :api_key)}"}).body)
    json["beans"].each { import_bean(it) } if json.key?("beans") && json["beans"].is_a?(Array)
  end

  def import_bean(bean)
    return if bean["link"]&.squish&.downcase&.match?(EXCLUDED_URLS_REGEX)

    parsed_date = Date.parse(bean["date"])
    return if parsed_date < @cut_off

    roaster_name = bean["roaster"]&.squish
    return if roaster_name.blank?

    attributes = COFFEE_BAG_JSON_MAPPING.to_h { |attr, key| [attr, bean[key]&.squish] }
    CanonicalCoffeeBag
      .find_or_initialize_by(loffee_labs_id: bean["id"])
      .update(canonical_roaster: roaster_by_name(roaster_name), **attributes)
  rescue Date::Error => e
    Appsignal.report_error(e) { it.set_tags(loffee_labs_id: bean["id"]) }
  end

  def roaster_by_name(name)
    @roasters[name] ||= CanonicalRoaster.find_or_create_by!(loffee_labs_id: name) { |r| r.name = name }
  end
end
