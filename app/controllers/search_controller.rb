# frozen_string_literal: true

class SearchController < ApplicationController
  include Pagy::Backend

  FILTERS = %i[profile_title bean_brand bean_type user].freeze

  before_action :authenticate_user!

  def index
    @shots = Shot.visible.by_start_time

    FILTERS.each do |filter|
      next if params[filter].blank?

      @shots = if filter == :user
                 @shots.where(user_id: params[:user_id])
               else
                 @shots.where("#{filter} ILIKE ?", "%#{params[filter]}%")
               end
    end

    @shots = @shots.where("espresso_enjoyment >= ?", params[:min_enjoyment]) if params[:min_enjoyment].present?
    @shots = @shots.where("espresso_enjoyment <= ?", params[:max_enjoyment]) if params[:max_enjoyment].present?

    @pagy, @shots = pagy(@shots)
  end

  def autocomplete
    query = params[:q].split(/\s+/).join(".*")
    @filter = params[:filter].to_sym
    @values = unique_values_for(@filter)
    @values = if @filter == :user
                @values.select { |u| u.name =~ /#{query}/i }
              else
                @values.grep(/#{query}/i)
              end
    render layout: false
  end

  def unique_values_for(filter)
    if filter == :user
      Rails.cache.fetch("#{User.visible.cache_key_with_version}/#{filter}") do
        User.visible.by_name
      end
    else
      Rails.cache.fetch("#{Shot.visible.cache_key_with_version}/#{filter}") do
        Shot.visible.distinct.pluck(filter).compact.map(&:strip).uniq(&:downcase).sort_by(&:downcase)
      end
    end
  end
end
