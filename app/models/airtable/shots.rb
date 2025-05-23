module Airtable
  class Shots < Base
    DB_TABLE_NAME = :shots
    TABLE_NAME = "Shots".freeze
    TABLE_DESCRIPTION = "Shots from Visualizer".freeze
    STANDARD_FIELDS = %w[
      espresso_enjoyment profile_title duration barista bean_weight drink_weight grinder_model grinder_setting
      bean_brand bean_type roast_date roast_level drink_tds drink_ey bean_notes espresso_notes private_notes
    ].index_by { it.to_s.humanize }
    FIELD_OPTIONS = {
      "espresso_enjoyment" => {type: "number", options: {precision: 0}},
      "duration" => {type: "duration", options: {durationFormat: "h:mm:ss.SS"}},
      "bean_notes" => {type: "richText"},
      "espresso_notes" => {type: "richText"},
      "private_notes" => {type: "richText"}
    }.freeze

    private

    def prepare_related_tables
      return unless user.coffee_management_enabled?

      [Roasters, CoffeeBags].each { |klass| klass.new(user) }
    end

    def table_fields
      @table_fields ||= begin
        static = [
          {name: "ID", type: "singleLineText"},
          {name: "URL", type: "url"},
          {name: "Image", type: "multipleAttachments"},
          {name: "Start time", type: "dateTime", options: {timeZone: "client", dateFormat: {name: "local"}, timeFormat: {name: "24hour"}}},
          {name: "Tags", type: "multipleSelects", options: {choices: user.tags.pluck("name").map { {name: it} }}}
        ]
        coffee_management = user.coffee_management_enabled? ? [{name: "Coffee Bag", type: "multipleRecordLinks", options: {linkedTableId: airtable_info.tables[CoffeeBags::TABLE_NAME]["id"]}}] : []
        standard = STANDARD_FIELDS.map { |name, attribute| {name:, **(FIELD_OPTIONS[attribute] || {type: "singleLineText"})} }
        metadata = user.metadata_fields.map { |field| {name: field, type: "singleLineText"} }

        static + coffee_management + standard + metadata
      end.map(&:deep_stringify_keys)
    end

    def prepare_record(shot)
      fields = {
        "ID" => shot.id,
        "URL" => shot_url(shot),
        "Start time" => shot.start_time,
        "Tags" => shot.tags.pluck(:name)
      }

      if user.coffee_management_enabled? && shot.coffee_bag.present?
        upload_coffee_bag_to_airtable(shot) unless shot.coffee_bag.airtable_id
        fields["Coffee Bag"] = [shot.coffee_bag.airtable_id]
      end

      STANDARD_FIELDS.each { |name, attribute| fields[name] = shot.public_send(attribute) }
      user.metadata_fields.each { |field| fields[field] = shot.metadata[field].to_s }
      fields["Image"] = [{url: shot.image.url(disposition: "attachment"), filename: shot.image.filename.to_s}] if shot.image.attached?
      data = {fields: fields.compact}
      data[:typecast] = true if fields["Tags"].present?
      data
    end

    def update_local_record(shot, record, updated_at)
      shot.assign_attributes(record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |k| STANDARD_FIELDS[k] })
      shot.skip_airtable_sync = true
      shot.updated_at = updated_at
      shot.metadata = user.metadata_fields.index_with { |f| record["fields"][f] }
      shot.tag_list = Array(record["fields"]["Tags"]).join(",")
      if user.coffee_management_enabled?
        bag_airtable_id = Array(record["fields"]["Coffee Bag"]).first
        shot.coffee_bag_id = bag_airtable_id.present? ? user.coffee_bags.find_by(airtable_id: bag_airtable_id)&.id : nil
        shot.skip_airtable_sync = false if shot.coffee_bag_id_changed?
      end
      shot.save!
    end

    def upload_coffee_bag_to_airtable(shot)
      AirtableUploadRecordJob.perform_now(shot.coffee_bag)
      shot.coffee_bag.reload
    end
  end
end
