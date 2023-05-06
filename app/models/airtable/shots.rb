# frozen_string_literal: true

module Airtable
  class Shots < Base
    include Rails.application.routes.url_helpers

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

    def upload(shot)
      if shot.airtable_id
        update_record(shot.airtable_id, prepare_record(shot))
      else
        upload_multiple(::Shot.where(id: shot.id))
      end
    end

    def upload_multiple(shots)
      records = shots.where(user:).with_attached_image.map { |shot| prepare_record(shot) }
      update_records(records) do |response|
        response["records"].each do |record|
          shot = shots.find_by(id: record["fields"]["ID"])
          next unless shot

          shot.update(airtable_id: record["id"], skip_airtable_sync: true)
        end
      end
    end

    def download(minutes: 60, timestamps: {})
      request_time = Time.zone.now
      records = get_records(minutes:)
      shots = user.shots.where(airtable_id: records.pluck("id")).index_by(&:airtable_id)
      records.each do |record|
        shot = shots[record["id"]]
        next unless shot

        attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] }
        attributes[:metadata] = user.metadata_fields.index_with { |f| record["fields"][f] }
        attributes[:updated_at] = timestamps[record["id"]].presence || request_time
        shot.update!(attributes.merge(skip_airtable_sync: true))
      end
    end

    def delete(airtable_id)
      delete_record(airtable_id)
    end

    private

    def prepare_table_fields
      static = [{name: "ID", type: "singleLineText"}, {name: "URL", type: "url"}, {name: "Start time", type: "dateTime", options: {timeZone: "client", dateFormat: {name: "local"}, timeFormat: {name: "24hour"}}}, {name: "Image", type: "multipleAttachments"}]
      standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }
      metadata = user.metadata_fields.map { |field| {name: field, type: "singleLineText"} }

      static + standard + metadata
    end

    def prepare_record(shot)
      fields = {"ID" => shot.id, "URL" => shot_url(shot), "Start time" => shot.start_time}
      STANDARD_FIELDS.each { |name, attribute| fields[name] = shot.public_send(attribute) }
      user.metadata_fields.each { |field| fields[field] = shot.metadata[field] }
      fields["Image"] = [{url: shot.image.url(disposition: "attachment"), filename: shot.image.filename.to_s}] if shot.image.attached?
      {fields:}
    end
  end
end
