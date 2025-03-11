class Shot
  module Jsonable
    extend ActiveSupport::Concern

    ALLOWED_ATTRIBUTES = %w[id duration profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes barista].freeze
    ALLOWED_FORMATS = %w[beanconqueror decent].freeze

    def to_api_json(format:, **options)
      method = ALLOWED_FORMATS.include?(format) ? :"#{format}_json" : :decent_json
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
        meta: {visualizer: visualizer_attributes}
      }
      add_brew_data(json)
      json.compact
    end

    def decent_json(include_information:)
      json = attributes.slice(*ALLOWED_ATTRIBUTES)
      add_brew_data(json) if include_information
      json.merge(visualizer_attributes.slice(*%i[start_time updated_at user_name metadata tags profile_url image_url roaster_id coffee_bag_id]))
    end

    private

    def visualizer_attributes
      attributes = {
        shot_id: id,
        user_id:,
        updated_at: updated_at.to_i,
        duration:,
        espresso_enjoyment:,
        espresso_notes:,
        bean_notes:,
        barista:,
        metadata: metadata.presence,
        tags: tags.pluck(:name),
        roaster_id: coffee_bag&.roaster&.id,
        coffee_bag_id: coffee_bag&.id
      }

      attributes[:start_time] = start_time unless user&.hide_shot_times
      attributes[:user_name] = user.display_name if user&.public?
      attributes[:profile_url] = Rails.application.routes.url_helpers.api_shot_profile_url(self) if information&.tcl_profile_fields.present?
      attributes[:image_url] = image.url if image.attached?

      attributes.compact
    end

    def add_brew_data(json)
      if information&.chart_data?
        json[:timeframe] = information&.timeframe
        json[:data] = information&.data
      else
        json[:brewdata] = information&.brewdata
      end
    end
  end
end
