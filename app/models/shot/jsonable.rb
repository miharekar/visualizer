class Shot
  module Jsonable
    extend ActiveSupport::Concern

    ALLOWED_ATTRIBUTES = %w[id duration profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date roast_level barista].freeze
    TIME_KEYS = %w[unix_timestamp updated_at start_time].freeze
    BREW_FLOW_TIMESTAMP = /\A([01]\d|2[0-3]):([0-5]\d):([0-5]\d)\.(\d+)\z/
    FORMAT_METHODS = {
      "beanconqueror" => :beanconqueror_json,
      "default" => :default_json,
      "decent" => :default_json
    }.freeze

    def to_api_json(format:, **options)
      method = FORMAT_METHODS.fetch(format, :default_json)
      public_send(method, **options)
    end

    def beanconqueror_json(**_options)
      json = {
        bean: {
          roaster: bean_brand,
          name: bean_type,
          roast: roast_level,
          roastingDate: iso8601_roast_date_time
        }.compact,
        mill: {name: grinder_model}.compact,
        brew: {
          grind_size: grinder_setting,
          brew_beverage_quantity: drink_weight,
          grind_weight: bean_weight,
          tds: drink_tds,
          ey: drink_ey
        }.compact,
        preparation: {name: profile_title}.compact,
        meta: {visualizer: visualizer_attributes(notes_format: :plain_text)}
      }
      add_brew_data(json)
      json.compact
    end

    def default_json(include_information:)
      json = attributes.slice(*ALLOWED_ATTRIBUTES)
      json["bean_notes"] = rich_text_html(:bean_notes)
      json["espresso_notes"] = rich_text_html(:espresso_notes)
      add_brew_data(json) if include_information
      json.merge(visualizer_attributes.slice(*%i[start_time updated_at user_name metadata tags profile_url image_url roaster_id coffee_bag_id private_notes fragrance aroma flavor aftertaste acidity bitterness sweetness mouthfeel]))
    end

    private

    def visualizer_attributes(notes_format: :html)
      attributes = {
        shot_id: id,
        user_id:,
        updated_at: (updated_at.to_i unless shot_times_hidden?),
        duration:,
        espresso_enjoyment:,
        fragrance:,
        aroma:,
        flavor:,
        aftertaste:,
        acidity:,
        bitterness:,
        sweetness:,
        mouthfeel:,
        espresso_notes: serialized_note(:espresso_notes, format: notes_format),
        bean_notes: serialized_note(:bean_notes, format: notes_format),
        barista:,
        metadata: metadata.presence,
        tags: tags.pluck(:name),
        roaster_id: coffee_bag&.roaster&.id,
        coffee_bag_id: coffee_bag&.id
      }

      attributes[:start_time] = start_time unless user&.hide_shot_times
      attributes[:user_name] = user.display_name if user&.public?
      attributes[:private_notes] = serialized_note(:private_notes, format: notes_format) if user && Current.user == user
      attributes[:profile_url] = Rails.application.routes.url_helpers.api_shot_profile_url(self) if information&.has_profile?
      attributes[:image_url] = image.url if image.attached?

      attributes.compact
    end

    def serialized_note(attribute, format:)
      format == :plain_text ? rich_text_plain_text(attribute) : rich_text_html(attribute)
    end

    def shot_times_hidden?
      user&.hide_shot_times? && Current.user != user
    end

    def add_brew_data(json)
      if information&.chart_data?
        json[:timeframe] = information&.timeframe
        json[:data] = information&.data
      else
        json[:brewdata] = brewdata_for_viewer
      end
    end

    def brewdata_for_viewer
      brewdata = information&.brewdata
      shot_times_hidden? && brewdata ? brewdata_without_times(brewdata) : brewdata
    end

    def brewdata_without_times(brewdata)
      brewdata = without_time_keys(brewdata)
      brew_flow = brewdata["brewFlow"]
      samples = brew_flow.is_a?(Hash) ? brew_flow.values.flatten.select { it.is_a?(Hash) } : []
      offsets = samples.map { brew_flow_milliseconds(it["timestamp"]) }
      start = offsets.compact.min
      samples.zip(offsets).each do |sample, milliseconds|
        if milliseconds
          sample["timestamp"] = Time.at(0, milliseconds - start, :millisecond).utc.strftime("%H:%M:%S.%L")
        else
          sample.delete("timestamp")
        end
      end
      brewdata
    end

    def brew_flow_milliseconds(timestamp)
      return unless timestamp.is_a?(String)

      match = BREW_FLOW_TIMESTAMP.match(timestamp)
      return unless match

      hours, minutes, seconds, fraction = match.captures
      ((hours.to_i * 60 + minutes.to_i) * 60 + seconds.to_i) * 1000 + fraction.ljust(3, "0")[0, 3].to_i
    end

    def without_time_keys(value)
      case value
      when Hash then value.except(*TIME_KEYS).transform_values { without_time_keys(it) }
      when Array then value.map { without_time_keys(it) }
      else value
      end
    end
  end
end
