# frozen_string_literal: true

class ShotsController < ApplicationController
  before_action :authenticate_user!, except: %i[new show random create chart]
  before_action :load_shot, only: %i[edit update destroy]
  before_action :load_users_shots, only: %i[index edit]
  before_action :skins_from_params, only: %i[show chart]

  def index; end

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
    redirect_to Shot.order("RANDOM()").first
  end

  def show
    @shot = Shot.find(params[:id])
    ScreenshotTakerJob.perform_later(@shot) if @shot.cloudinary_id.blank?
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
    @stages = @shot.stages
  end

  def bulk
    Array(params[:files]).each do |file|
      Shot.from_file(current_user, file: file)&.save
    end

    flash[:notice] = "Shots succesfully uploaded."
    if params.key?(:drag)
      head :ok
    else
      redirect_to({action: :index})
    end
  end

  def create
    @shot = Shot.from_file(current_user, file: params["file"])

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

  def skins_from_params
    @skins = ["Classic", "DSx", "White DSx"].map do |skin|
      {
        name: skin.parameterize,
        label: skin,
        checked: params[:skin] == skin.parameterize
      }
    end
    @skins[0][:checked] = true unless @skins.find { |s| s[:checked] }
  end
end
