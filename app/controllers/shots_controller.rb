# frozen_string_literal: true

class ShotsController < ApplicationController
  before_action :authenticate_user!, except: %i[new show random create]
  before_action :load_shot, only: %i[edit update destroy]
  before_action :load_users_shots, only: %i[index edit]

  def index; end

  def new; end

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
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
    @skins = skins_from_params
    @stages = @shot.stages
  end

  def bulk
    Array(params[:files]).each do |file|
      shot_from_file(file)&.save
    end

    redirect_to action: :index
  end

  def create
    @shot = shot_from_file(params["file"])

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
    params.require(:shot).permit(:profile_title, :comment, *Shot::EXTRA_DATA)
  end

  def shot_from_file(file)
    return unless file

    parsed_shot = ShotParser.new(File.read(file))
    Shot.find_or_create_by(user: current_user, sha: parsed_shot.sha) do |shot|
      shot.start_time = parsed_shot.start_time
      shot.profile_title = parsed_shot.profile_title
      shot.data = parsed_shot.data
      shot.extra = parsed_shot.extra
    end
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
