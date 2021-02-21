# frozen_string_literal: true

class SearchController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!

  def index
    @shots = Shot.visible

    %i[bean_brand bean_type].each do |method|
      unique_values = Rails.cache.fetch("#{@shots.cache_key_with_version}/#{method}") { @shots.distinct.pluck(method).compact }
      instance_variable_set("@#{method.to_s.pluralize}", unique_values.sort_by(&:downcase))
    end

    @shots = @shots.includes(:user).order(start_time: :desc)

    @shots = @shots.where("bean_brand ILIKE ?", "%#{params[:bean_brand]}%") if params[:bean_brand].present?
    @shots = @shots.where("bean_type ILIKE ?", "%#{params[:bean_type]}%") if params[:bean_type].present?

    @pagy, @shots = pagy(@shots)
  end
end
