module Airtable
  class CoffeeBags < Base
    DB_TABLE_NAME = :coffee_bags
    TABLE_NAME = "Coffee Bags".freeze
    TABLE_DESCRIPTION = "Coffee Bags from Visualizer".freeze
    STANDARD_FIELDS = %w[
      country elevation farm farmer harvest_time processing quality_score region roast_date frozen_date defrosted_date roast_level variety tasting_notes archived_at place_of_purchase notes
    ].index_by { |f| f.to_s.humanize }
    FIELD_OPTIONS = {
      "roast_date" => {type: "date", options: {dateFormat: {name: "local"}}},
      "frozen_date" => {type: "date", options: {dateFormat: {name: "local"}}},
      "defrosted_date" => {type: "date", options: {dateFormat: {name: "local"}}},
      "archived_at" => {type: "dateTime", options: {timeZone: "utc", dateFormat: {name: "local"}, timeFormat: {name: "24hour"}}},
      "notes" => {type: "richText"}
    }.freeze

    private

    def table_fields
      @table_fields ||= begin
        static = [
          {name: "Name", type: "singleLineText"},
          {name: "ID", type: "singleLineText"},
          {name: "URL", type: "url"},
          {name: "Image", type: "multipleAttachments"},
          {name: "Roaster", type: "multipleRecordLinks", options: {linkedTableId: airtable_info.tables[Roasters::TABLE_NAME]["id"]}}
        ]
        standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }

        static + standard
      end.map(&:deep_stringify_keys)
    end

    def prepare_record(coffee_bag)
      upload_roaster_to_airtable(coffee_bag) unless coffee_bag.roaster.airtable_id

      fields = {
        "Name" => coffee_bag.name,
        "Roaster" => [coffee_bag.roaster.airtable_id],
        "ID" => coffee_bag.id,
        "URL" => shots_url(coffee_bag:)
      }
      STANDARD_FIELDS.each { |name, attribute| fields[name] = coffee_bag.public_send(attribute) }
      fields["Image"] = [{url: coffee_bag.image.url(disposition: "attachment"), filename: coffee_bag.image.filename.to_s}] if coffee_bag.image.attached?
      {fields:}
    end

    def update_local_record(coffee_bag, record, updated_at)
      attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] }
      attributes[:name] = record["fields"]["Name"]
      roaster_airtable_id = Array(record["fields"]["Roaster"]).first
      roaster = user.roasters.find_by(airtable_id: roaster_airtable_id)
      attributes[:roaster_id] = roaster.id if roaster_airtable_id.present? && roaster.present?
      coffee_bag.update!(attributes.merge(skip_airtable_sync: true, updated_at:))
    end

    def upload_roaster_to_airtable(coffee_bag)
      AirtableUploadRecordJob.perform_now(coffee_bag.roaster)
      coffee_bag.roaster.reload
    end
  end
end
