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
    editable = columns.except("actions", "ratio", "image", "start_time")
    user.coffee_management_enabled? ? editable.except(*BAG_FIELDS) : editable
  end

  def dropdown_values(field)
    DropdownValue.visible.for(user, field).pluck(:value)
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
    return user.update!(journal_columns: nil) if settings.nil?

    order = settings["order"]
    hidden = settings["hidden"]
    raise InvalidChange, "Unknown columns" unless order.is_a?(Array) && hidden.is_a?(Array) && order.all? { it.is_a?(String) } && hidden.all? { it.is_a?(String) } && (order + hidden - columns.keys).empty?

    user.update!(journal_columns: {order: order.uniq, hidden: hidden.uniq})
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
    shots = shots.with_attached_image if fields.include?("image")
    shots = shots.includes(:tags) if fields.include?("tag_list")
    shots
  end

  def shots(ids, fields: visible_columns, lock: false)
    raise InvalidChange, "Choose up to #{MAX_BATCH} shots" unless ids.is_a?(Array) && ids.size.between?(1, MAX_BATCH) && ids.uniq.size == ids.size && ids.all? { it.is_a?(String) && it.match?(UUID_PATTERN) }

    shots = for_list(scope.where(id: ids).reorder(:id).lock(lock), fields: fields.uniq)
    (fields & NOTES).each { shots = shots.public_send("with_rich_text_#{it}_and_embeds") }
    shots = shots.to_a
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
    elsif field == "tag_list"
      shot.tag_list
    else
      shot[field]
    end
  end

  def update(ids, field:, value:)
    raise InvalidChange, "Some fields are not editable" unless editable_columns.key?(field)
    raise InvalidChange, "Invalid field value" unless value.nil? || value.is_a?(String)

    Shot.transaction do
      records = shots(ids, fields: [field], lock: true)
      yield records if block_given?
      if field == "coffee"
        raise InvalidChange, "Choose a coffee bag" if value.blank?

        user.coffee_bags.find(value)
      end
      records.each do |shot|
        raise InvalidChange, "Some fields are not editable" if field == "duration" && !shot.manual?

        # Tag assignment writes immediately, so assignment must stay inside this transaction.
        shot.assign_attributes(attributes_for(shot, field, value))
        shot.save!(context: %i[update manual_edit])
      end
      records
    end
  end

  private

  def attributes_for(shot, field, value)
    if field == "coffee"
      {coffee_bag_id: value}
    elsif field.start_with?("metadata:")
      {metadata: shot.metadata.merge(field.delete_prefix("metadata:") => value)}
    elsif %w[bean_brand bean_type].include?(field)
      {field => value, coffee_bag_id: nil, canonical_coffee_bag_id: nil}
    else
      {field => value}
    end
  end
end
