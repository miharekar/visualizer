module ShotHelper
  def shot_copyable_label(form, attribute, text = nil, &block)
    tag.div(class: "flex justify-between items-center gap-2") do
      concat form.label(attribute, text, class: "standard-label")
      concat tag.div(class: "flex items-center gap-2") {
        concat capture(&block) if block_given?
        concat link_to("Revert", "#", class: "hidden text-sm font-light standard-link text-neutral-500 dark:text-neutral-400", data: {action: "click->shot-copier#rollback", revert_for: form.field_id(attribute)})
      }
    end
  end

  def shot_copyable_label_tag(label_for, revert_for, text)
    tag.div(class: "flex justify-between items-center gap-2") do
      concat label_tag(label_for, text, class: "standard-label")
      concat tag.div(class: "flex items-center gap-2") {
        concat link_to("Revert", "#", class: "hidden text-sm font-light standard-link text-neutral-500 dark:text-neutral-400", data: {action: "click->shot-copier#rollbackTags", revert_for:})
      }
    end
  end

  def tasting_assessment_categories
    Shot::TASTING_ASSESSMENT_ATTRIBUTES.map { it.to_s.humanize }
  end

  def tasting_assessment_series(shot, name:)
    values = Shot::TASTING_ASSESSMENT_ATTRIBUTES.map { |attribute| shot.public_send(attribute).to_i }
    return if values.all?(0)

    {name:, data: values}
  end

  def metadata_pair(key, value)
    value = brewdata_input_value(value)
    return unless value

    tag.tr do
      concat tag.td(key, class: "whitespace-nowrap")
      concat tag.td(value, class: "wrap-anywhere")
    end
  end

  def brewdata_input_value(value)
    return if value.is_a?(Hash) || value.is_a?(Array)

    value_string = value.to_s
    return if value_string.blank? || value_string == "0" || value_string == "UNKNOWN"

    value_string
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
