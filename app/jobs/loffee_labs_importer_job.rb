class LoffeeLabsImporterJob < ApplicationJob
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

  def perform
    import_roasters
    import_beans
  end

  private

  def import_roasters
    CSV.foreach("storage/roasters.csv", headers: true) do |row|
      name = row["roaster"]&.squish
      next if name.blank?

      roaster = CanonicalRoaster.find_or_initialize_by(loffee_labs_id: name)
      roaster.update!(ROASTER_CSV_MAPPING.to_h { |attr, col| [attr, row[col]&.squish] })
    end
  end

  def import_beans
    uri = URI("https://www.loffeelabs.com/wp-json/beanbase/v1/beans?api_key=#{Rails.application.credentials.dig(:loffee_labs, :api_key)}")
    req = Net::HTTP::Get.new(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(req)
    return unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)["data"].each do |bean|
      roaster_name = bean["roaster"]&.squish
      next if roaster_name.blank?

      roaster = CanonicalRoaster.find_or_create_by!(loffee_labs_id: roaster_name) { |r| r.name = roaster_name }
      attributes = COFFEE_BAG_JSON_MAPPING.to_h { |attr, key| [attr, bean[key]&.squish] }
      CanonicalCoffeeBag.find_or_initialize_by(loffee_labs_id: bean["id"]).update!(
        canonical_roaster: roaster,
        **attributes
      )
    end
  end
end
