class CommunityController < ApplicationController
  include Filterable
  include Paginatable

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
    return head :not_found if params[:filter].blank?

    @filter = params[:filter].to_sym
    @values = values_for_query(@filter, params[:q])
    render layout: false
  end

  def trending
    @trending_24h = cached_trending("24h")
    @trending_30d = cached_trending("30d")
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
    @shots = Shot.visible_or_owned_by_id(Current.user&.id).includes(:user).with_attached_image
    apply_standard_filters_to_shots

    find_user_by_name if params[:user].present? && params[:user_id].blank?
    @shots = @shots.where(user_id: params[:user_id]) if params[:user_id].present?
  end

  def find_user_by_name
    user = values_for_query(:user, params[:user]).first
    return if user.nil?

    params[:user_id] = user.id
    params[:user] = user.display_name
  end

  def values_for_query(filter, query)
    return [] if query.blank?

    query_parts = query.split(/\s+/).map { Regexp.escape(it) }
    rquery = /#{query_parts.join(".*")}/i
    values = unique_values_for(filter)
    return [] if values.blank?

    if filter == :user
      values.select { it.display_name =~ rquery }
    else
      values.grep(rquery)
    end
  end

  def cached_trending(window)
    Rails.cache.read("community/trending/#{window}") || {profiles: [], parsers: [], public_count: 0, total_count: 0}
  end
end
