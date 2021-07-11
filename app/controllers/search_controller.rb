# frozen_string_literal: true

class SearchController < ApplicationController
  include Pagy::Backend

  FILTERS = %i[profile_title bean_brand bean_type user].freeze

  before_action :authenticate_user!

  def index
    @shots = Shot.visible.with_avatars.by_start_time

    @filters = {}
    FILTERS.each do |filter|
      @filters[filter] = unique_values_for(filter)
      next if params[filter].blank?

      @shots = if filter == :user
                 @shots.where(user_id: params[filter])
               else
                 @shots.where("#{filter} ILIKE ?", "%#{params[filter]}%")
               end
    end

    min = params[:min_enjoyment].to_i
    max = params[:max_enjoyment].to_i
    @shots = @shots.where(espresso_enjoyment: (min..)) if min.positive?
    @shots = @shots.where(espresso_enjoyment: (..max)) if max < 100

    @pagy, @shots = pagy(@shots)
  end

  def unique_values_for(filter)
    Rails.cache.fetch("#{Shot.visible.cache_key_with_version}/#{filter}") do
      if filter == :user
        User.visible.by_name
      else
        Shot.visible.distinct.pluck(filter).compact.map(&:strip).uniq(&:downcase).sort_by(&:downcase)
      end
    end
  end
end
