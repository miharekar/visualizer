class Journal
  class InvalidChange < StandardError; end
  class Conflict < InvalidChange; end

  PAGE_SIZE = 30
  MAX_BATCH = 100
  DEFAULT_COLUMNS = %w[espresso_enjoyment start_time coffee profile_title bean_weight drink_weight duration grinder_setting espresso_notes].freeze
  LABELS = {
    "start_time" => "Brewed", "coffee" => "Coffee", "profile_title" => "Profile",
    "bean_weight" => "Dose (g)", "drink_weight" => "Yield (g)", "duration" => "Time (s)",
    "grinder_setting" => "Grind", "espresso_enjoyment" => "Enjoyment", "espresso_notes" => "Notes",
    "grinder_model" => "Grinder", "bean_brand" => "Roaster", "bean_type" => "Coffee name",
    "barista" => "Barista", "roast_date" => "Roast date", "roast_level" => "Roast level",
    "drink_tds" => "TDS", "drink_ey" => "EY", "bean_notes" => "Bean notes"
  }.freeze
  NOTES = %w[espresso_notes bean_notes private_notes].freeze
  COFFEE_FIELDS = %w[coffee_bag_id canonical_coffee_bag_id bean_brand bean_type roast_date roast_level].freeze

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def scope
    user.premium? ? user.shots : user.shots.non_premium
  end

  def columns
    labels = LABELS.dup
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
    saved + (DEFAULT_COLUMNS - saved) + (columns.keys - saved - DEFAULT_COLUMNS)
  end

  def visible_columns
    hidden = Array(user.journal_columns["hidden"])
    if user.journal_columns.empty?
      DEFAULT_COLUMNS
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
    if params[:q].present?
      query = "%#{Shot.sanitize_sql_like(params[:q])}%"
      fields = %w[profile_title bean_brand bean_type grinder_model espresso_notes bean_notes]
      fields << "private_notes" if user.premium?
      shots = shots.where(fields.map { "#{it} ILIKE :query" }.join(" OR "), query:)
    end
    shots = shots.where(coffee_bag_id: user.coffee_bags.find(params[:coffee_bag]).id) if params[:coffee_bag].present? && user.coffee_management_enabled?
    shots = shots.with_all_tag_slugs(params[:tags]) if user.premium? && params[:tags].present?
    if params[:start_date].present?
      date = Date.iso8601(params[:start_date])
      shots = shots.where(start_time: date.in_time_zone.all_day)
    end
    shots
  rescue Date::Error
    raise InvalidChange, "Choose a valid brew date"
  end

  def page(shots, params)
    if params[:before].present?
      raise InvalidChange, "Invalid journal cursor" unless params[:before].is_a?(String)

      cursor = verifier.verified(params[:before], purpose: "journal-page:#{user.id}")
      raise InvalidChange, "Invalid journal cursor" unless cursor.is_a?(Hash) && cursor["time"].present? && cursor["id"].present?

      shots = shots.where("(start_time, shots.id) < (?, ?)", cursor["time"], cursor["id"])
    end
    records = shots.reorder(start_time: :desc, id: :desc).with_notes.includes(:tags, :information).limit(PAGE_SIZE + 1).to_a
    if records.size > PAGE_SIZE
      records.pop
      last = records.last
      cursor = verifier.generate({"time" => last.start_time.utc.iso8601(6), "id" => last.id}, purpose: "journal-page:#{user.id}", expires_in: 1.day)
    else
      cursor = nil
    end
    [records, cursor]
  end

  def value(shot, field)
    if NOTES.include?(field)
      shot.rich_text_html(field)
    elsif field.start_with?("metadata:")
      shot.metadata[field.delete_prefix("metadata:")]
    elsif field == "coffee"
      [shot.bean_brand, shot.bean_type].compact_blank.join(" / ")
    elsif field == "start_time"
      shot.start_time.in_time_zone(Current.timezone).strftime("%Y-%m-%dT%H:%M:%S")
    else
      shot.public_send(field)
    end
  end

  def update(changes)
    raise InvalidChange, "Choose between 1 and #{MAX_BATCH} distinct shots" unless changes.is_a?(Array) && changes.size.between?(1, MAX_BATCH) && changes.all? { it.is_a?(Hash) } && changes.pluck("id").uniq.size == changes.size

    previous = []
    shots = []
    user.with_lock do
      records = locked_shots(changes.pluck("id"))
      changes.sort_by { it["id"].to_s }.each do |change|
        shot = records.fetch(change["id"])
        check_version(shot, change["version"])
        attributes = permitted_attributes(shot, change["attributes"])
        metadata_keys = change["attributes"]["metadata"]&.keys
        before = snapshot(shot, attributes, metadata_keys:)
        shot.assign_attributes(attributes)
        shot.updated_at = Time.current
        shot.save!
        shot.reload
        previous << {"id" => shot.id, "attributes" => before, "after" => snapshot(shot, attributes, metadata_keys:)}
        shots << shot
      end
    end
    [shots, verifier.generate(previous, purpose: "journal:#{user.id}", expires_in: 12.hours)]
  end

  def undo(token)
    raise InvalidChange, "Invalid undo" unless token.is_a?(String)

    previous = verifier.verified(token, purpose: "journal:#{user.id}")
    raise InvalidChange, "Undo expired; reload to see current values" unless previous.is_a?(Array)

    shots = []
    user.with_lock do
      records = locked_shots(previous.pluck("id"))
      previous.sort_by { it["id"] }.each do |change|
        shot = records.fetch(change["id"])
        current = snapshot(shot, change["attributes"], metadata_keys: change["attributes"]["metadata"]&.keys)
        raise Conflict, "These fields changed since saving. Reload before reverting." unless current == change["after"]

        attributes = permitted_attributes(shot, change["attributes"])
        # Persist assignment callbacks first, then restore exact signed snapshot.
        shot.update!(attributes)
        shot.assign_attributes(attributes)
        shot.updated_at = Time.current
        shot.save!
        shots << shot
      end
    end
    shots
  end

  def create(attributes, entry_id)
    raise InvalidChange, "Invalid draft identifier" unless entry_id.is_a?(String) && entry_id.match?(/\A[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}\z/i)

    user.with_lock do
      existing = scope.find_by(id: entry_id)
      if existing
        raise InvalidChange, "This identifier already belongs to an imported shot" unless existing.manual?

        scope.find(existing.id)
      else
        raise ActiveRecord::RecordNotFound if Shot.exists?(id: entry_id)

        shot = user.shots.new(id: entry_id, sha: "manual:#{SecureRandom.uuid}", public: user.public, start_time: Time.current)
        shot.assign_attributes(permitted_attributes(shot, attributes))
        shot.save!
        shot
      end
    end
  end

  private

  def locked_shots(ids)
    records = scope.where(id: ids).order(:id).lock.with_notes.includes(:information, :tags, coffee_bag: :roaster).index_by(&:id)
    raise ActiveRecord::RecordNotFound unless records.size == ids.size && ids.all? { records.key?(it) }

    records
  end

  def permitted_attributes(shot, attributes)
    raise InvalidChange, "Missing changed fields" unless attributes.is_a?(Hash) && attributes.present?

    allowed = Shot.editable_attributes(user).reject { it == :image }
    allowed += %i[start_time duration] if shot.manual?
    permitted = ActionController::Parameters.new(attributes).permit(*allowed).to_h
    raise InvalidChange, "Some fields are not editable" unless (attributes.keys - permitted.keys).empty?

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

  def snapshot(shot, attributes, metadata_keys: nil)
    keys = attributes.keys
    keys |= COFFEE_FIELDS if (keys & %w[coffee_bag_id canonical_coffee_bag_id]).any?
    keys -= ["coffee_bag_id"] unless user.coffee_management_enabled?
    keys.index_with do |field|
      if NOTES.include?(field)
        shot.rich_text_html(field)
      elsif field == "metadata"
        shot.metadata.slice(*metadata_keys)
      elsif field == "start_time"
        shot.start_time.iso8601(6)
      else
        shot.public_send(field)
      end
    end
  end

  def check_version(shot, version)
    raise Conflict, "Shot changed elsewhere. Reload before editing or reverting." unless version == shot.updated_at.utc.iso8601(6)
  end

  def verifier
    Rails.application.message_verifier(:journal_undo)
  end
end
