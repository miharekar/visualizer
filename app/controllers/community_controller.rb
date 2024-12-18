class CommunityController < ApplicationController
  include CursorPaginatable

  FILTERS = {
    profile_title: {autocomplete: true},
    bean_brand: {autocomplete: true},
    bean_type: {autocomplete: true},
    user: {autocomplete: true, target: :user_id},
    grinder_model: {autocomplete: true},
    roast_level: {autocomplete: true},
    bean_notes: {},
    espresso_notes: {}
  }.freeze

  def index
    if params[:commit] || Current.user.blank? || Current.user.premium?
      load_shots
      @shots = @shots.non_premium unless Current.user&.premium?
      @shots, @cursor = paginate_with_cursor(@shots.for_list, by: :start_time, before: params[:before])
    else
      @shots = []
    end
  end

  def banner
    load_shots
    @premium_count = Rails.cache.fetch("premium_count/#{@shots.to_sql}", expires_in: 1.hour) { @shots.premium.count }
  end

  def autocomplete
    @filter = params[:filter].to_sym
    @values = values_for_query(@filter, params[:q])
    render layout: false
  end

  def unique_values_for(filter)
    if filter == :user
      User.visible_or_id(Current.user&.id).order_by_name
    else
      Rails.cache.read("unique_values_for_#{filter}")
    end
  end

  private

  def load_shots
    @shots = Shot.visible_or_owned_by_id(Current.user&.id).includes(:user)
    FILTERS.each do |filter, options|
      next if params[filter].blank?

      @shots = if options[:target]
        find_user_by_name if filter == :user && params[options[:target]].blank?
        @shots.where(options[:target] => params[options[:target]])
      else
        @shots.where("#{filter} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[filter])}%")
      end
    end
    @shots = @shots.where(espresso_enjoyment: (params[:min_enjoyment])..) if params[:min_enjoyment].to_i.positive?
    @shots = @shots.where(espresso_enjoyment: ..(params[:max_enjoyment])) if params[:max_enjoyment].present? && params[:max_enjoyment].to_i < 100
  end

  def find_user_by_name
    user = values_for_query(:user, params[:user]).first
    return if user.nil?

    params[:user_id] = user.id
    params[:user] = user.display_name
  end

  def values_for_query(filter, query)
    query_parts = query.split(/\s+/).map { |q| Regexp.escape(q) }
    rquery = /#{query_parts.join(".*")}/i
    values = unique_values_for(filter)
    return [] if values.blank?

    if filter == :user
      values.select { it.display_name =~ rquery }
    else
      values.grep(rquery)
    end
  end
end
