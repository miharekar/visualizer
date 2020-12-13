# frozen_string_literal: true

class ShotsController < ApplicationController
  before_action :authenticate_user!, except: %i[new show random create]
  before_action :load_shot, only: %i[edit update destroy]

  def new; end

  def index
    @shots = Shot.where(user: current_user).order(start_time: :desc)
  end

  def random
    redirect_to Shot.order("RANDOM()").first
  end

  def show
    @shot = Shot.find(params[:id])
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
    @skins = skins_from_params
    @stages = @shot.stages
  end

  def bulk
    params[:files].each do |file|
      shot_from_file(file).save
    end

    redirect_to action: :index
  end

  def create
    @shot = shot_from_file(params["file"])

    if @shot.save
      if params.key?(:drag)
        render json: {id: @shot.id}
      else
        redirect_to @shot
      end
    else
      render :new
    end
  end

  def edit; end

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
    @shot = Shot.where(user: current_user).find(params[:id])
  end

  def shot_params
    params.require(:shot).permit(:profile_title, :comment, *Shot::EXTRA_DATA)
  end

  def shot_from_file(file)
    parsed_shot = ShotParser.new(File.read(file))
    Shot.new(
      user: current_user,
      start_time: parsed_shot.start_time,
      profile_title: parsed_shot.profile_title,
      data: parsed_shot.data,
      extra: parsed_shot.extra
    )
  end

  def skins_from_params
    skins = ["Classic", "DSx", "White DSx"].map do |skin|
      {
        name: skin.parameterize,
        label: skin,
        checked: params[:skin] == skin.parameterize
      }
    end
    skins[0][:checked] = true unless skins.find { |s| s[:checked] }

    skins
  end
end
