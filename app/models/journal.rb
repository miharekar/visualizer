class Journal
  class InvalidChange < StandardError; end

  PAGE_SIZE = 30
  MAX_BATCH = 100
  UUID_PATTERN = /\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i
  DEFAULT_COLUMNS = %w[espresso_enjoyment start_time coffee profile_title bean_weight grinder_setting grinder_model drink_weight duration actions].freeze
  LABELS = {
    "start_time" => "Made at", "coffee" => "Coffee", "profile_title" => "Profile",
    "bean_weight" => "Dose (g)", "drink_weight" => "Yield (g)", "duration" => "Time (s)",
    "grinder_setting" => "Grind", "espresso_enjoyment" => "Enjoyment", "espresso_notes" => "Notes",
    "grinder_model" => "Grinder", "bean_brand" => "Roaster", "bean_type" => "Coffee bag",
    "barista" => "Barista", "roast_date" => "Roast date", "roast_level" => "Roast level",
    "drink_tds" => "TDS", "drink_ey" => "EY", "bean_notes" => "Bean notes", "ratio" => "Ratio", "image" => "Photo", "actions" => "Actions"
  }.freeze
  NOTES = %w[espresso_notes bean_notes private_notes].freeze
  COFFEE_FIELDS = %w[coffee_bag_id canonical_coffee_bag_id bean_brand bean_type roast_date roast_level].freeze
  BAG_FIELDS = %w[bean_brand bean_type roast_date roast_level].freeze
  DROPDOWN_FIELDS = %w[grinder_model bean_brand bean_type].freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def scope
    user.premium? ? user.shots : user.shots.non_premium
  end

  def columns
    labels = LABELS.dup
    if user.coffee_management_enabled?
      labels.except!("bean_brand", "bean_type")
    else
      labels.delete("coffee")
    end
    if user.premium?
      labels["tag_list"] = "Tags"
      labels["private_notes"] = "Private notes"
      Shot::TASTING_ASSESSMENT_ATTRIBUTES.each { labels[it.to_s] = it.to_s.humanize }
      user.shot_metadata_fields.each { labels["metadata:#{it}"] = it.humanize }
    end
    labels
  end

  def ordered_columns
    saved = Array(user.journal_columns["order"]) & columns.keys
    saved + (default_columns - saved) + (columns.keys - saved - default_columns)
  end

  def default_columns
    DEFAULT_COLUMNS.flat_map { it == "coffee" && !user.coffee_management_enabled? ? %w[bean_brand bean_type] : it } & columns.keys
  end

  def editable_columns
    editable = columns.except("actions", "ratio", "image")
    user.coffee_management_enabled? ? editable.except(*BAG_FIELDS) : editable
  end

  def dropdown_values(field)
    @dropdown_values ||= {}
    @dropdown_values[field] ||= DropdownValue.visible.for(user, field).pluck(:value)
  end

  def visible_columns
    hidden = Array(user.journal_columns["hidden"])
    if user.journal_columns.empty?
      default_columns
    else
      ordered_columns - hidden
    end
  end

  def save_columns(settings)
    return user.with_lock { user.update!(journal_columns: nil) } if settings.nil?

    order = settings["order"]
    hidden = settings["hidden"]
    raise InvalidChange, "Unknown columns" unless order.is_a?(Array) && hidden.is_a?(Array) && order.all? { it.is_a?(String) } && hidden.all? { it.is_a?(String) } && (order + hidden - columns.keys).empty?

    user.with_lock do
      # Preserve preferences for premium columns while subscription is inactive.
      unavailable_order = Array(user.journal_columns["order"]) - columns.keys
      unavailable_hidden = Array(user.journal_columns["hidden"]) - columns.keys
      user.update!(journal_columns: {order: order.uniq + unavailable_order, hidden: hidden.uniq + unavailable_hidden})
    end
  end

  def search(params)
    shots = scope
    params[:q].to_s.split.each do |term|
      query = "%#{Shot.sanitize_sql_like(term)}%"
      matches = scope.where(<<~SQL.squish, query:)
        profile_title ILIKE :query OR bean_brand ILIKE :query OR bean_type ILIKE :query
        OR grinder_model ILIKE :query OR espresso_notes ILIKE :query
        OR bean_notes ILIKE :query OR roast_date ILIKE :query
      SQL
      if user.premium?
        matches = matches.or(scope.where("private_notes ILIKE ?", query))
        tags = user.tags.where("name ILIKE ?", query).select(:id)
        matches = matches.or(scope.where(id: ShotTag.where(tag_id: tags).select(:shot_id)))
      end
      shots = shots.merge(matches)
    end
    shots = shots.where(coffee_bag_id: user.coffee_bags.find(params[:coffee_bag]).id) if params[:coffee_bag].present? && user.coffee_management_enabled?
    shots = shots.with_all_tag_slugs(params[:tags]) if user.premium? && params[:tags].present?
    shots
  end

  def page(shots, params)
    if params[:before].present?
      raise InvalidChange, "Invalid journal cursor" unless params[:before].is_a?(String) && params[:before_id].is_a?(String) && params[:before_id].match?(UUID_PATTERN)

      shots = shots.where("(start_time, shots.id) < (?, ?)", Time.iso8601(params[:before]), params[:before_id])
    end
    records = for_list(shots).reorder(start_time: :desc, id: :desc).limit(PAGE_SIZE + 1).to_a
    if records.size > PAGE_SIZE
      records.pop
      last = records.last
      cursor = {before: last.start_time.utc.iso8601(6), before_id: last.id}
    else
      cursor = nil
    end
    [records, cursor]
  rescue ArgumentError
    raise InvalidChange, "Invalid journal cursor"
  end

  def for_list(shots = scope, fields: visible_columns)
    shots = shots.with_information_presence
    (fields & NOTES).each { shots = shots.public_send("with_rich_text_#{it}_and_embeds") }
    shots = shots.with_attached_image if fields.include?("image")
    shots = shots.includes(:tags) if fields.include?("tag_list")
    shots
  end

  def shots(ids, fields: visible_columns)
    raise InvalidChange, "Choose up to #{MAX_BATCH} shots" unless ids.is_a?(Array) && ids.size.between?(1, MAX_BATCH) && ids.uniq.size == ids.size && ids.all? { it.is_a?(String) && it.match?(UUID_PATTERN) }

    shots = for_list(scope.where(id: ids), fields: fields.uniq).to_a
    raise ActiveRecord::RecordNotFound unless shots.size == ids.size

    shots
  end

  def value(shot, field)
    if %w[actions image].include?(field)
      nil
    elsif field == "ratio"
      "1:#{shot.weight_ratio.round(1)}" if shot.bean_weight_f.positive? && shot.drink_weight_f.positive?
    elsif NOTES.include?(field)
      shot.rich_text_html(field)
    elsif field.start_with?("metadata:")
      shot.metadata[field.delete_prefix("metadata:")]
    elsif field == "coffee"
      name = [shot.bean_type, shot.bean_brand].compact_blank.join(" - ")
      shot.roast_date.present? ? "#{name} (#{shot.roast_date})" : name
    elsif field == "start_time"
      shot.start_time.in_time_zone(Current.timezone).strftime("%Y-%m-%dT%H:%M:%S")
    elsif field == "tag_list"
      shot.tag_list
    else
      shot[field]
    end
  end

  def update(ids, attributes)
    raise InvalidChange, "Missing changed fields" unless attributes.is_a?(Hash) && attributes.present?

    user.with_lock do
      records = shots(ids).sort_by(&:id)
      records.each do |shot|
        shot.lock!
        # Tag assignment writes immediately, so assignment must stay inside this transaction.
        shot.update!(permitted_attributes(shot, attributes.deep_stringify_keys))
      end
      records
    end
  end

  private

  def permitted_attributes(shot, attributes)
    raise InvalidChange, "Missing changed fields" unless attributes.is_a?(Hash) && attributes.present?

    allowed = Shot.editable_attributes(user).reject { it == :image }
    allowed = allowed.reject { BAG_FIELDS.include?(it.to_s) } if user.coffee_management_enabled?
    allowed += %i[start_time duration] if (attributes.keys & %w[start_time duration]).any? && shot.manual?
    permitted = ActionController::Parameters.new(attributes).permit(*allowed).to_h
    raise InvalidChange, "Some fields are not editable" unless (attributes.keys - permitted.keys).empty?

    permitted["canonical_coffee_bag_id"] = nil if !user.coffee_management_enabled? && (attributes.keys & %w[bean_brand bean_type]).any?

    if permitted.key?("metadata")
      raise InvalidChange, "Unknown custom field" unless attributes["metadata"].is_a?(Hash) && (attributes["metadata"].keys - user.shot_metadata_fields).empty?

      permitted["metadata"] = shot.metadata.merge(permitted["metadata"])
    end
    user.coffee_bags.find(permitted["coffee_bag_id"]) if permitted["coffee_bag_id"].present?
    CanonicalCoffeeBag.find(permitted["canonical_coffee_bag_id"]) if permitted["canonical_coffee_bag_id"].present?
    permitted["start_time"] = Time.find_zone!(Current.timezone.name).iso8601(permitted["start_time"].to_s) if permitted.key?("start_time")
    if permitted["duration"].present?
      duration = Float(permitted["duration"])
      raise InvalidChange, "Duration must be a nonnegative number" unless duration.finite? && duration >= 0

      permitted["duration"] = duration
    end
    if permitted["espresso_enjoyment"].present?
      score = Integer(permitted["espresso_enjoyment"].to_s, 10)
      raise InvalidChange, "Enjoyment must be between 0 and 100" unless score.between?(0, 100)
    end
    permitted
  rescue ArgumentError, TypeError
    raise InvalidChange, "Invalid date or numeric value"
  end
end
