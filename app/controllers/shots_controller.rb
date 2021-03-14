# frozen_string_literal: true

class ShotsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: %i[show chart]
  before_action :load_shot, only: %i[edit update destroy]

  FILTER_PARAMS = %i[bean_brand bean_type].freeze

  def index
    load_shots_with_pagy
  end

  def chart
    @no_header = true
    @shot = Shot.find(params[:shot_id])
    _, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
  end

  def edit
    shots = current_user.shots
    %i[grinder_model bean_brand bean_type].each do |method|
      unique_values = Rails.cache.fetch("#{shots.cache_key_with_version}/#{method}") { shots.distinct.pluck(method).compact }
      instance_variable_set("@#{method.to_s.pluralize}", unique_values.sort_by(&:downcase))
    end
  end

  def show
    @shot = Shot.find(params[:id])
    # TODO: Rethink this ScreenshotTakerJob.perform_later(@shot) if @shot.cloudinary_id.blank?
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
    @stages = @shot.stages

    @highcharts_data = @main_data.map do |line|
      {
        name: line[:label],
        data: line[:data].map { |d| [d[:t], d[:y]] },
        visible: %w[espresso_water_dispensed espresso_weight].exclude?(line[:label])
      }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to :root
  end

  def create
    files = Array(params[:files])
    files.each do |file|
      Shot.from_file(current_user, file)&.save
    end

    flash[:notice] = "#{'Shot'.pluralize(files.count)} successfully uploaded."
    if params.key?(:drag)
      head :ok
    else
      redirect_to({action: :index})
    end
  end

  def update
    @shot.update(shot_params)
    flash[:notice] = "Shot successfully updated."
    redirect_to action: :show
  end

  def destroy
    @shot.destroy!

    respond_to do |format|
      format.turbo_stream do
        if request.referer.ends_with?("shots/#{@shot.id}")
          flash[:notice] = "Shot successfully deleted."
          redirect_to action: :index
        else
          load_shots_with_pagy
          if @shots.any?
            render turbo_stream: turbo_stream.replace("shot-list", partial: "shots/list", locals: {shots: @shots, pagy: @pagy, url: shots_path(extra_params)})
          else
            redirect_to action: :index
          end
        end
      end
      format.html do
        flash[:notice] = "Shot successfully deleted."
        redirect_to action: :index
      end
    end
  end

  private

  def load_shot
    @shot = current_user.shots.find(params[:id])
  end

  def shot_params
    params.require(:shot).permit(:profile_title, :bean_weight, *Shot::EXTRA_DATA_METHODS)
  end

  def load_shots_with_pagy
    @shots = current_user.shots.order(start_time: :desc)
    FILTER_PARAMS.each do |filter|
      next if params[filter].blank?

      @shots = @shots.where(filter => params[filter]) if params[filter]
    end
    @pagy, @shots = pagy(@shots)
  end

  def extra_params
    FILTER_PARAMS.map do |filter|
      next if params[filter].blank?

      [filter, params[filter]]
    end.compact.to_h
  end
end
