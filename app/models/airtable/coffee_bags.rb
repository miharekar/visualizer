module Airtable
  class CoffeeBags < Base
    TABLE_DESCRIPTION = "Coffee Bags from Visualizer"
    STANDARD_FIELDS = %w[
      name country elevation farm farmer harvest_time processing quality_score region roast_date roast_level variety
    ].index_by { |f| f.to_s.humanize }
    FIELD_OPTIONS = {
      "roast_date" => {type: "date", options: {dateFormat: {name: "local"}}},
    }

    private

    def table_fields
      @table_fields ||= begin
        static = [{name: "ID", type: "singleLineText"}, {name: "URL", type: "url"}, {name: "Image", type: "multipleAttachments"}]
        standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }

        static + standard
      end.map(&:deep_stringify_keys)
    end

    def prepare_record(coffee_bag)
      fields = {"ID" => coffee_bag.id, "URL" => roaster_coffee_bags_url(coffee_bag.roaster_id)}
      STANDARD_FIELDS.each { |name, attribute| fields[name] = coffee_bag.public_send(attribute) }
      fields["Image"] = [{url: coffee_bag.image.url(disposition: "attachment"), filename: coffee_bag.image.filename.to_s}] if coffee_bag.image.attached?
      {fields: fields.compact}
    end

    def update_local_record(coffee_bag, record, updated_at)
        # TODO: Implement this
    end
  end
end
