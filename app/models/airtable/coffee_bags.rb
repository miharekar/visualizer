module Airtable
  class CoffeeBags < Base
    DB_TABLE_NAME = :coffee_bags
    TABLE_NAME = "Coffee Bags".freeze
    TABLE_DESCRIPTION = "Coffee Bags from Visualizer".freeze
    STANDARD_FIELDS = %w[
      country elevation farm farmer harvest_time processing quality_score region roast_date roast_level variety
    ].index_by { |f| f.to_s.humanize }
    FIELD_OPTIONS = {
      "roast_date" => {type: "date", options: {dateFormat: {name: "local"}}}
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
      fields = {
        "Name" => coffee_bag.name,
        "Roaster" => [coffee_bag.roaster.airtable_id],
        "ID" => coffee_bag.id,
        "URL" => roaster_coffee_bags_url(coffee_bag.roaster_id)
      }
      STANDARD_FIELDS.each { |name, attribute| fields[name] = coffee_bag.public_send(attribute) }
      fields["Image"] = [{url: coffee_bag.image.url(disposition: "attachment"), filename: coffee_bag.image.filename.to_s}] if coffee_bag.image.attached?
      {fields: fields.compact}
    end

    def local_record_attributes(record)
      attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] }
      attributes[:name] = record["fields"]["Name"]
      attributes
    end
  end
end
