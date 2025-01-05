module Jsonable
  extend ActiveSupport::Concern

  ALLOWED_ATTRIBUTES = %w[id duration profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes barista].freeze
  STANDARD_PARSERS = %w[beanconqueror].freeze

  def to_api_json(with_data: false, standard_format: false)
    standard_format ? standard_json : decent_json(with_data)
  end

  private

  def standard_json
    if STANDARD_PARSERS.include?(information.parser_name)
      json = information.brewdata.deep_dup
      json.delete("parser")
    else
      json = {brewflow: information.attributes.slice(*%w[data timeframe])}
    end

    json = json.deep_merge(
      "bean" => {
        "roaster" => bean_brand,
        "name" => bean_type,
        "roast" => roast_level,
        "roastingDate" => iso8601_roast_date_time
      }.compact,
      "mill" => {"name" => grinder_model}.compact,
      "brew" => {
        "grind_size" => grinder_setting,
        "brew_beverage_quantity" => drink_weight,
        "grind_weight" => bean_weight,
        "tds" => drink_tds,
        "ey" => drink_ey
      }.compact,
      "preparation" => {"name" => profile_title}.compact,
      "meta" => {"visualizer" => visualizer_attributes}
    )

    json.compact
  end

  def decent_json(with_data)
    json = attributes.slice(*ALLOWED_ATTRIBUTES)

    if with_data
      if information&.chart_data?
        json[:timeframe] = information&.timeframe
        json[:data] = information&.data
      else
        json[:brewdata] = information&.brewdata
      end
    end

    json.merge(visualizer_attributes.slice(:start_time, :user_name, :metadata, :tags, :image_preview, :profile_url))
  end

  def visualizer_attributes
    attributes = {
      shot_id: id,
      user_id:,
      duration:,
      espresso_enjoyment:,
      espresso_notes:,
      bean_notes:,
      barista:
    }

    attributes[:start_time] = start_time unless user&.hide_shot_times
    attributes[:user_name] = user.display_name if user&.public?
    attributes[:metadata] = metadata.presence if user&.premium?
    attributes[:tags] = tags.pluck(:name) if user&.premium?
    attributes[:profile_url] = Rails.application.routes.url_helpers.api_shot_profile_url(self) if information&.tcl_profile_fields.present?

    attributes.compact
  end
end
