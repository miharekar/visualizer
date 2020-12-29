# frozen_string_literal: true

class ShotsController < ApplicationController
  include Pagy::Backend

  before_action :authenticate_user!, except: %i[new show random create chart]
  before_action :load_shot, only: %i[edit update destroy]
  before_action :load_users_shots, only: %i[index edit]

  FILTER_PARAMS = %i[bean_brand bean_type].freeze

  def index
    @filter_params = {}
    FILTER_PARAMS.each do |filter|
      if params[filter]
        @shots = @shots.select { |s| s.public_send(filter) == params[filter] }
        @filter_params[filter] = params[filter]
      end
    end

    if @shots.is_a?(Array)
      @pagy, @shots = pagy_array(@shots)
    else
      @pagy, @shots = pagy(@shots)
    end

    render json: {next: @pagy.next, html: render_to_string(partial: "shots/pagy", locals: {shots: @shots})} if params[:page]
  end

  def new; end

  def chart
    @no_header = true
    @shot = Shot.find(params[:shot_id])
    _, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
  end

  def edit
    @grinder_models = @shots.map(&:grinder_model).uniq.compact
    @bean_brands = @shots.map(&:bean_brand).uniq.compact
    @bean_types = @shots.map(&:bean_type).uniq.compact
  end

  def random
    redirect_to Shot.where(user: User.where(public: true)).order("RANDOM()").first
  end

  def show
    @shot = Shot.find(params[:id])
    ScreenshotTakerJob.perform_later(@shot) if @shot.cloudinary_id.blank?
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
    @stages = @shot.stages
  rescue ActiveRecord::RecordNotFound
    redirect_to :root
  end

  def bulk
    Array(params[:files]).each do |file|
      Shot.from_file(current_user, file)&.save
    end

    flash[:notice] = "Shots succesfully uploaded."
    if params.key?(:drag)
      head :ok
    else
      redirect_to({action: :index})
    end
  end

  def create
    @shot = Shot.from_file(current_user, params["file"])

    if @shot&.save
      if params.key?(:drag)
        render json: {id: @shot.id}
      else
        redirect_to @shot
      end
    else
      render :new
    end
  end

  def update
    @shot.update(shot_params)
    redirect_to action: :show
  end

  def destroy
    @shot.destroy
    redirect_to action: :index
  end

  private

  def load_shot
    @shot = current_user.shots.find(params[:id])
  end

  def load_users_shots
    @shots = current_user.shots.order(start_time: :desc)
  end

  def shot_params
    params.require(:shot).permit(:profile_title, *Shot::EXTRA_DATA)
  end
end
