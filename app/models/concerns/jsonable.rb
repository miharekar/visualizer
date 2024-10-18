module Jsonable
  extend ActiveSupport::Concern

  STANDARD_PARSERS = %w[beanconqueror].freeze

  def to_api_json(with_data: false)
    STANDARD_PARSERS.include?(information&.parser_name) ? standard_json : decent_json(with_data)
  end

  private

  def standard_json
    # TODO
  end

  def decent_json(with_data)
    json = attributes.slice(*allowed_attributes)

    if with_data
      json[:timeframe] = information&.timeframe
      json[:data] = information&.data
    end

    json[:user_name] = user.display_name if user&.public?
    json[:image_preview] = screenshot_url if screenshot?
    json[:profile_url] = Rails.application.routes.url_helpers.api_shot_profile_url(self) if information&.tcl_profile_fields.present?

    json
  end

  def allowed_attributes
    attrs = %w[id duration profile_title user_id drink_tds drink_ey espresso_enjoyment bean_weight drink_weight grinder_model grinder_setting bean_brand bean_type roast_date espresso_notes roast_level bean_notes barista]
    attrs += %w[start_time] unless user&.hide_shot_times
    attrs += %w[metadata] if user&.premium?
    attrs
  end
end
