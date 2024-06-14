module Airtable
  class Roasters < Base
    TABLE_DESCRIPTION = "Roasters from Visualizer"
    STANDARD_FIELDS = %w[
      name website
    ].index_by { |f| f.to_s.humanize }
    FIELD_OPTIONS = {
      "website" => {type: "url"}
    }

    def upload(roaster)
      if roaster.airtable_id
        update_record(roaster.airtable_id, prepare_record(roaster))
      else
        upload_multiple(::Roaster.where(user:, id: roaster.id))
      end
    end

    def upload_multiple(roasters)
      return unless roasters.exists?

      records = roasters.with_attached_image.map { |roaster| prepare_record(roaster) }
      update_records(records) do |response|
        response["records"].each do |record|
          roaster = roasters.find_by(id: record["fields"]["ID"])
          next unless roaster

          roaster.update(airtable_id: record["id"], skip_airtable_sync: true)
        end
      end
    end

    def download(minutes: 60, timestamps: {})
      request_time = Time.zone.now
      records = get_records(minutes:)
      roasters = user.roasters.where(airtable_id: records.pluck("id")).index_by(&:airtable_id)
      records.each do |record|
        roaster = roasters[record["id"]]
        next unless roaster

        attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] }
        attributes[:metadata] = user.metadata_fields.index_with { |f| record["fields"][f] }
        attributes[:updated_at] = timestamps[record["id"]].presence || request_time
        roaster.update!(attributes.merge(skip_airtable_sync: true))
      end
    end

    def delete(airtable_id)
      delete_record(airtable_id)
    end

    private

    def table_fields
      @table_fields ||= begin
        static = [{name: "ID", type: "singleLineText"}, {name: "URL", type: "url"}, {name: "Image", type: "multipleAttachments"}]
        standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }

        static + standard
      end.map(&:deep_stringify_keys)
    end

    def prepare_record(roaster)
      fields = {"ID" => roaster.id, "URL" => roaster_url(roaster)}
      STANDARD_FIELDS.each { |name, attribute| fields[name] = roaster.public_send(attribute) }
      fields["Image"] = [{url: roaster.image.url(disposition: "attachment"), filename: roaster.image.filename.to_s}] if roaster.image.attached?
      {fields: fields.compact}
    end
  end
end
