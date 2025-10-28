class LoffeeLabsImporterJob < ApplicationJob
  retry_on TypeError, wait: :polynomially_longer

  queue_as :low

  ROASTER_CSV_MAPPING = {name: "roaster", website: "link", country: "country", address: "locality"}.freeze
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

  def perform(cut_off: 3.months.ago)
    @cut_off = cut_off
    @roasters = {}
    import_roasters
    import_beans
  end

  private

  def import_roasters
    url = Rails.application.credentials.dig(:loffee_labs, :roasters_url)
    CSV.parse(SimpleDownloader.new(url).body, headers: true).each do |row|
      name = row["roaster"]&.squish
      next if name.blank?

      @roasters[name] = CanonicalRoaster.find_or_initialize_by(loffee_labs_id: name)
      @roasters[name].update(ROASTER_CSV_MAPPING.to_h { |attr, col| [attr, row[col]&.squish] })
    end
  end

  def import_beans
    url = "https://www.loffeelabs.com/wp-json/beanbase/v1/beans?api_key=#{Rails.application.credentials.dig(:loffee_labs, :api_key)}"
    JSON.parse(SimpleDownloader.new(url).body)["data"].each do |bean|
      next if Date.parse(bean["date"]) < @cut_off

      roaster_name = bean["roaster"]&.squish
      next if roaster_name.blank?

      attributes = COFFEE_BAG_JSON_MAPPING.to_h { |attr, key| [attr, bean[key]&.squish] }
      CanonicalCoffeeBag
        .find_or_initialize_by(loffee_labs_id: bean["id"])
        .update(canonical_roaster: roaster_by_name(roaster_name), **attributes)
    end
  end

  def roaster_by_name(name)
    @roasters[name] ||= CanonicalRoaster.find_or_create_by!(loffee_labs_id: name) { |r| r.name = name }
  end
end
