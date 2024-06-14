module Airtable
  class Shots < Base
    TABLE_DESCRIPTION = "Shots from Visualizer"
    STANDARD_FIELDS = %w[
      espresso_enjoyment profile_title duration barista bean_weight drink_weight grinder_model grinder_setting
      bean_brand bean_type roast_date roast_level drink_tds drink_ey bean_notes espresso_notes private_notes
    ].index_by { |f| f.to_s.humanize }
    FIELD_OPTIONS = {
      "espresso_enjoyment" => {type: "number", options: {precision: 0}},
      "duration" => {type: "duration", options: {durationFormat: "h:mm:ss.SS"}},
      "bean_notes" => {type: "richText"},
      "espresso_notes" => {type: "richText"},
      "private_notes" => {type: "richText"}
    }

    private

    def table_fields
      @table_fields ||= begin
        static = [{name: "ID", type: "singleLineText"}, {name: "URL", type: "url"}, {name: "Start time", type: "dateTime", options: {timeZone: "client", dateFormat: {name: "local"}, timeFormat: {name: "24hour"}}}, {name: "Image", type: "multipleAttachments"}]
        standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }
        metadata = user.metadata_fields.map { |field| {name: field, type: "singleLineText"} }

        static + standard + metadata
      end.map(&:deep_stringify_keys)
    end

    def prepare_record(shot)
      fields = {"ID" => shot.id, "URL" => shot_url(shot), "Start time" => shot.start_time}
      STANDARD_FIELDS.each { |name, attribute| fields[name] = shot.public_send(attribute) }
      user.metadata_fields.each { |field| fields[field] = shot.metadata[field].to_s }
      fields["Image"] = [{url: shot.image.url(disposition: "attachment"), filename: shot.image.filename.to_s}] if shot.image.attached?
      {fields: fields.compact}
    end

    def update_local_record(shot, record, updated_at)
      attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] }
      attributes[:metadata] = user.metadata_fields.index_with { |f| record["fields"][f] }
      attributes[:updated_at] = updated_at
      shot.update!(attributes.merge(skip_airtable_sync: true))
    end
  end
end
