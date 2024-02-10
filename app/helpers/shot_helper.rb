# frozen_string_literal: true

module ShotHelper
  def metadata_pair(key, value)
    value = value.to_s
    return if value.blank? || value == "0" || value == "UNKNOWN"

    tag.div do
      concat tag.span((key + ":&nbsp;").html_safe)
      concat tag.span(value)
    end
  end
end
