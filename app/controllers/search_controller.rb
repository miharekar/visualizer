# frozen_string_literal: true

class SearchController < ApplicationController
  include Pagy::Backend

  FILTERS = %i[profile_title bean_brand bean_type].freeze

  before_action :authenticate_user!

  def index
    @shots = Shot.visible.with_avatars.by_start_time

    @filters = {}
    FILTERS.each do |filter|
      @filters[filter] = unique_values_for(filter)
      @shots = @shots.where("#{filter} ILIKE ?", "%#{params[filter]}%") if params[filter].present?
    end

    @pagy, @shots = pagy(@shots)
  end

  def unique_values_for(filter)
    Rails.cache.fetch("#{Shot.visible.cache_key_with_version}/#{filter}") do
      Shot.visible.distinct.pluck(filter).compact.map(&:strip).uniq.sort_by(&:downcase)
    end
  end
end
