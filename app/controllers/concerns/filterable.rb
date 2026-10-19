module Filterable
  FILTERS = {
    profile_title: {autocomplete: true},
    bean_brand: {autocomplete: true},
    bean_type: {autocomplete: true},
    grinder_model: {autocomplete: true},
    bean_notes: {},
    espresso_notes: {}
  }.freeze

  # indexed_only restricts to the autocomplete (gin_trgm-indexed) text columns —
  # bean_notes/espresso_notes have no index, so a public, paginated API endpoint
  # must not offer them as filters any caller could trigger a sequential scan with.
  def apply_standard_filters_to_shots(indexed_only: false)
    FILTERS.each do |filter, options|
      next if indexed_only && !options[:autocomplete]
      next if params[filter].blank?

      @shots = @shots.where("#{filter} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[filter])}%")
    end
    apply_date_and_enjoyment_filters
  end

  def apply_date_and_enjoyment_filters
    if params[:start_date].present?
      start_date = Date.iso8601(params[:start_date]) rescue nil
      @shots = @shots.where(start_time: start_date.all_day) if start_date
    end
    @shots = @shots.where(espresso_enjoyment: (params[:min_enjoyment])..) if params[:min_enjoyment].to_i.positive?
    @shots = @shots.where(espresso_enjoyment: ..(params[:max_enjoyment])) if params[:max_enjoyment].present? && params[:max_enjoyment].to_i < 100
  end
end
