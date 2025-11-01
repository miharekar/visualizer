module ShotHelper
  def metadata_pair(key, value)
    value = value.to_s
    return if value.blank? || value == "0" || value == "UNKNOWN"

    tag.tr do
      concat tag.td(key, class: "whitespace-nowrap")
      concat tag.td(value, class: "wrap-anywhere")
    end
  end

  def meta_description(shot)
    parts = []

    if shot.bean_brand.present? || shot.bean_type.present?
      bean_info = [shot.bean_brand, shot.bean_type].compact.join(" ")
      parts << bean_info
    end

    bean_weight = shot.bean_weight_f
    drink_weight = shot.drink_weight_f
    ratio = drink_weight / bean_weight if bean_weight.positive? && drink_weight.positive?

    weights = []
    weights << "#{bean_weight}g" if bean_weight.positive?
    weights << "#{drink_weight}g" if drink_weight.positive?
    if weights.any?
      weight_part = weights.join(":")
      weight_part << " (1:#{ratio.round(1)})" if ratio&.positive? && ratio&.finite?
      weight_part << " in #{shot.duration.round(1)}s"
      parts << weight_part
    else
      parts << "in #{shot.duration.round(1)}s"
    end

    grinder_parts = []
    grinder_parts << shot.grinder_model if shot.grinder_model.present?
    grinder_parts << "@ #{shot.grinder_setting}" if shot.grinder_setting.present? && ["0", "0.0"].exclude?(shot.grinder_setting)
    parts << grinder_parts.join(" ") if grinder_parts.any?

    tds = shot.drink_tds.to_f
    parts << "TDS #{tds}%" if tds.positive?

    ey = shot.drink_ey.to_f
    parts << "EY #{ey}%" if ey.positive?

    parts.join(" | ")
  end
end
