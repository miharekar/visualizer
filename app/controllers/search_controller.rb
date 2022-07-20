# frozen_string_literal: true

class SearchController < ApplicationController
  include Pagy::Backend

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

  before_action :authenticate_user!

  def index
    if params[:commit]
      @shots = Shot.visible_or_owned_by_id(current_user.id).by_start_time.includes(:user)
      @shots = @shots.non_premium unless current_user.premium?
      FILTERS.each do |filter, options|
        next if params[filter].blank?

        @shots = if options[:target]
                   find_user_by_name if filter == :user && params[options[:target]].blank?
                   @shots.where(options[:target] => params[options[:target]])
                 else
                   @shots.where("#{filter} ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[filter])}%")
                 end
      end
      @shots = @shots.where("espresso_enjoyment >= ?", params[:min_enjoyment]) if params[:min_enjoyment].to_i.positive?
      @shots = @shots.where("espresso_enjoyment <= ?", params[:max_enjoyment]) if params[:max_enjoyment].present? && params[:max_enjoyment].to_i < 100
      @pagy, @shots = pagy_countless(@shots)
    else
      @shots = []
    end
  end

  def autocomplete
    @filter = params[:filter].to_sym
    @values = values_for_query(@filter, params[:q])
    render layout: false
  end

  def unique_values_for(filter)
    if filter == :user
      User.visible_or_id(current_user.id).by_name
    else
      Rails.cache.fetch("#{Shot.visible.cache_key_with_version}/#{filter}") do
        Shot.visible.distinct.pluck(filter).compact.map(&:strip).uniq(&:downcase).sort_by(&:downcase)
      end
    end
  end

  private

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
    if filter == :user
      values.select { |u| u.display_name =~ rquery }
    else
      values.grep(rquery)
    end
  end
end
