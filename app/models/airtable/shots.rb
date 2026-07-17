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
    MARKDOWN_NOTE_FIELDS = %w[bean_notes espresso_notes private_notes].to_h { |attribute| [attribute.humanize, "legacy_#{attribute}"] }.freeze
    HTML_NOTE_FIELDS = %w[bean_notes espresso_notes private_notes].index_by { |attribute| "#{attribute.humanize} HTML" }.freeze
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
        standard = standard_fields.map { |name, attribute| {name:, **field_options(name, attribute)} }
        metadata = user.shot_metadata_fields.map { |field| {name: field, type: "singleLineText"} }

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

      standard_fields.each do |name, attribute|
        value = shot.public_send(attribute)
        fields[name] = name.end_with?(" HTML") ? shot.note_html(attribute) : value
      end
      user.shot_metadata_fields.each { |field| fields[field] = shot.metadata[field].to_s }
      fields["Image"] = [{url: shot.image.url(disposition: "attachment"), filename: shot.image.filename.to_s}] if shot.image.attached?
      data = {fields: fields.compact}
      data[:typecast] = true if fields["Tags"].present?
      data
    end

    def update_local_record(shot, record, updated_at)
      attributes = record["fields"].slice(*standard_fields.keys).transform_keys { |key| standard_fields[key] }
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

    def standard_fields
      @standard_fields ||= STANDARD_FIELDS.merge(user.rich_text_enabled? ? HTML_NOTE_FIELDS : MARKDOWN_NOTE_FIELDS)
    end

    def field_options(name, attribute)
      return {type: "multilineText"} if name.end_with?(" HTML")
      return {type: "richText"} if MARKDOWN_NOTE_FIELDS.key?(name)

      FIELD_OPTIONS[attribute] || {type: "singleLineText"}
    end
  end
end
