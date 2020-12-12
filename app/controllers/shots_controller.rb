# frozen_string_literal: true

class ShotsController < ApplicationController
  before_action :authenticate_user!, only: :index

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

  def create
    parsed_shot = ShotParser.new(File.read(params["file"]))
    @shot = Shot.new(
      user: current_user,
      start_time: parsed_shot.start_time,
      profile_title: parsed_shot.profile_title,
      data: parsed_shot.data,
      extra: parsed_shot.extra
    )

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

  def destroy
    @shot = Shot.where(user: current_user).find(params[:id])
    @shot.destroy
    redirect_to action: :index
  end

  private

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
