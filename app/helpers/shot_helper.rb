module ShotHelper
  def metadata_pair(key, value)
    value = value.to_s
    return if value.blank? || value == "0" || value == "UNKNOWN"

    tag.tr do
      concat tag.td(key, class: "whitespace-nowrap")
      concat tag.td(value)
    end
  end
end
