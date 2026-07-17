module Airtable
  class Shots < Base
    DB_TABLE_NAME = :shots
    TABLE_NAME = "Shots".freeze
    TABLE_DESCRIPTION = "Shots from Visualizer".freeze
    STANDARD_FIELDS = %w[
      espresso_enjoyment profile_title duration barista bean_weight drink_weight grinder_model grinder_setting
      bean_brand bean_type roast_date roast_level drink_tds drink_ey
      fragrance aroma flavor aftertaste acidity bitterness sweetness mouthfeel
    ].index_by { it.to_s.humanize }
    NOTE_FIELDS = %w[bean_notes espresso_notes private_notes].index_by { it.humanize }.freeze
    FIELD_OPTIONS = {
      "espresso_enjoyment" => {type: "number", options: {precision: 0}},
      "duration" => {type: "duration", options: {durationFormat: "h:mm:ss.SS"}},
      "fragrance" => {type: "number", options: {precision: 0}},
      "aroma" => {type: "number", options: {precision: 0}},
      "flavor" => {type: "number", options: {precision: 0}},
      "aftertaste" => {type: "number", options: {precision: 0}},
      "acidity" => {type: "number", options: {precision: 0}},
      "bitterness" => {type: "number", options: {precision: 0}},
      "sweetness" => {type: "number", options: {precision: 0}},
      "mouthfeel" => {type: "number", options: {precision: 0}}
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
        notes = note_fields.map { |name, _attribute| {name:, type: note_field_type} }
        metadata = user.shot_metadata_fields.map { |field| {name: field, type: "singleLineText"} }

        static + coffee_management + standard + notes + metadata
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
      note_fields.each { |name, attribute| fields[name] = user.rich_text_enabled? ? shot.note_html(attribute) : shot.public_send(attribute) }
      user.shot_metadata_fields.each { |field| fields[field] = shot.metadata[field].to_s }
      fields["Image"] = [{url: shot.image.url(disposition: "attachment"), filename: shot.image.filename.to_s}] if shot.image.attached?
      data = {fields: fields.compact}
      data[:typecast] = true if fields["Tags"].present?
      data
    end

    def update_local_record(shot, record, updated_at)
      attributes = record["fields"].slice(*STANDARD_FIELDS.keys).transform_keys { |key| STANDARD_FIELDS[key] }
      attributes.merge!(record["fields"].slice(*note_fields.keys).transform_keys { |key| note_fields[key] })
      shot.assign_attributes(attributes)
      shot.skip_airtable_sync = true
      shot.updated_at = updated_at
      shot.metadata = user.shot_metadata_fields.index_with { |f| record["fields"][f] }
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

    def note_fields
      @note_fields ||= NOTE_FIELDS.transform_keys { |name| user.rich_text_enabled? ? "#{name} HTML" : name }
    end

    def note_field_type
      user.rich_text_enabled? ? "multilineText" : "richText"
    end
  end
end
