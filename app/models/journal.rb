class Journal
  class InvalidChange < StandardError; end

  PAGE_SIZE = 30
  MAX_BATCH = 100
  DEFAULT_COLUMNS = %w[espresso_enjoyment start_time coffee profile_title bean_weight grinder_setting grinder_model drink_weight duration actions].freeze
  LABELS = {
    "start_time" => "Brewed at", "coffee" => "Coffee", "profile_title" => "Profile",
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
    return @columns if @columns

    labels = LABELS.dup
    if user.coffee_management_enabled?
      labels.except!(*BAG_FIELDS)
    else
      labels.delete("coffee")
    end
    if user.premium?
      labels["tag_list"] = "Tags"
      labels["private_notes"] = "Private notes"
      Shot::TASTING_ASSESSMENT_ATTRIBUTES.each { labels[it.to_s] = it.to_s.humanize }
      user.shot_metadata_fields.each { labels["metadata:#{it}"] = it.humanize }
    end
    @columns = labels
  end

  def ordered_columns
    visible_columns + (columns.keys - visible_columns)
  end

  def default_columns
    with_coffee_columns(DEFAULT_COLUMNS) & columns.keys
  end

  def editable_columns
    @editable_columns ||= columns.except("actions", "ratio", "image", "start_time")
  end

  def dropdown_values(field)
    DropdownValue.visible.for(user, field).pluck(:value)
  end

  def visible_columns
    @visible_columns ||= user.journal_columns.nil? ? default_columns : with_coffee_columns(user.journal_columns) & columns.keys
  end

  def save_columns(settings)
    raise InvalidChange, "Invalid columns" unless settings.is_a?(Array) && settings.all? { it.is_a?(String) }

    settings &= columns.keys
    user.update!(journal_columns: settings == default_columns ? nil : settings)
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
    coffee_bag = filtered_coffee_bag(params[:coffee_bag])
    shots = shots.where(coffee_bag:) if coffee_bag
    tags = filtered_tags(params[:tags])
    shots = shots.with_all_tag_slugs(tags) if tags.any?
    shots
  end

  def filter_labels(params)
    [filtered_coffee_bag(params[:coffee_bag])&.display_name, *filtered_tags(params[:tags])].compact
  end

  def for_list(shots = scope, fields: visible_columns)
    shots = shots.with_attached_image if fields.include?("image")
    shots = shots.includes(:tags) if fields.include?("tag_list")
    shots
  end

  def shots(ids, fields: visible_columns)
    raise InvalidChange, "Choose up to #{MAX_BATCH} shots" unless ids.is_a?(Array) && ids.size.between?(1, MAX_BATCH) && ids.uniq.size == ids.size && ids.all? { it.is_a?(String) && it.match?(ApplicationRecord::UUID_PATTERN) }

    shots = for_list(scope.where(id: ids).reorder(:id), fields: fields.uniq)
    (fields & NOTES).each { shots = shots.public_send("with_rich_text_#{it}_and_embeds") }
    shots = shots.to_a
    raise ActiveRecord::RecordNotFound unless shots.size == ids.size

    shots
  end

  def editor_value(shots, field)
    if field == "tag_list"
      shots.map { it.tags.map(&:name) }.reduce(:&).sort.join(",")
    elsif field == "coffee" && shots.one?
      shots.first.coffee_bag_id
    elsif shots.one?
      value(shots.first, field)
    end
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
      label = [shot.bean_type, shot.bean_brand].compact_blank.join(" - ")
      date = shot.parsed_roast_date
      date ? "#{label} (#{date.to_fs(:long)})".strip : label
    elsif field == "tag_list"
      shot.tag_list
    else
      shot[field]
    end
  end

  def update(records, field:, value:)
    raise InvalidChange, "Some fields are not editable" unless editable_columns.key?(field)
    raise InvalidChange, "Invalid field value" unless value.nil? || value.is_a?(String)

    Shot.transaction do
      if field == "coffee"
        value = user.coffee_bags.includes(:roaster).find_by(id: value)
        raise InvalidChange, "Choose a coffee bag" unless value
      end
      records.each do |shot|
        raise InvalidChange, "Some fields are not editable" if field == "duration" && !shot.manual?

        shot.assign_attributes(attributes_for(shot, field, value))
        shot.save!(context: %i[update manual_edit])
      end
    end
    %w[bean_weight drink_weight].include?(field) ? [field, "ratio"] : [field]
  end

  private

  def with_coffee_columns(fields)
    if user.coffee_management_enabled?
      fields.map { BAG_FIELDS.include?(it) ? "coffee" : it }.uniq
    else
      fields.flat_map { it == "coffee" ? %w[bean_brand bean_type] : it }.uniq
    end
  end

  def filtered_coffee_bag(id)
    user.coffee_bags.find_by(id:) if id.present? && user.coffee_management_enabled?
  end

  def filtered_tags(tags)
    user.premium? ? tags.to_s.split(",").compact_blank : []
  end

  def attributes_for(shot, field, value)
    if field == "coffee"
      {coffee_bag: value}
    elsif field.start_with?("metadata:")
      {metadata: shot.metadata.merge(field.delete_prefix("metadata:") => value)}
    elsif %w[bean_brand bean_type].include?(field)
      {field => value, coffee_bag_id: nil, canonical_coffee_bag_id: nil}
    else
      {field => value}
    end
  end
end
