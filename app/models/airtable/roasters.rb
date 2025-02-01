module Airtable
  class Roasters < Base
    DB_TABLE_NAME = :roasters
    TABLE_NAME = "Roasters".freeze
    TABLE_DESCRIPTION = "Roasters from Visualizer".freeze
    STANDARD_FIELDS = %w[
      website
    ].index_by { |f| f.to_s.humanize }
    FIELD_OPTIONS = {
      "website" => {type: "url"}
    }.freeze

    private

    def table_fields
      @table_fields ||= begin
        static = [
          {name: "Name", type: "singleLineText"},
          {name: "ID", type: "singleLineText"},
          {name: "URL", type: "url"},
          {name: "Image", type: "multipleAttachments"}
        ]
        standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }

        static + standard
      end.map(&:deep_stringify_keys)
    end

    def prepare_record(roaster)
      fields = {
        "Name" => roaster.name,
        "ID" => roaster.id,
        "URL" => roaster_coffee_bags_url(roaster)
      }
      STANDARD_FIELDS.each { |name, attribute| fields[name] = roaster.public_send(attribute) }
      fields["Image"] = [{url: roaster.image.url(disposition: "attachment"), filename: roaster.image.filename.to_s}] if roaster.image.attached?
      {fields: fields.compact}
    end

    def update_local_record(roaster, record, updated_at)
      attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] }
      attributes[:name] = record["fields"]["Name"]
      roaster.update!(attributes.merge(skip_airtable_sync: true, updated_at:))
    end
  end
end
