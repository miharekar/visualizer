class ShotsController < ApplicationController
  # GET /shots/1
  def show
    @shot = Shot.find(params[:id])
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
    @skins = skins_from_params
    @stages = @shot.stages
  end

  # POST /shots
  def create
    parsed_shot = ShotParser.new(File.read(params["file"]))
    @shot = Shot.new(
      start_time: parsed_shot.start_time,
      profile_title: parsed_shot.profile_title,
      data: parsed_shot.data
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

  private

  def skins_from_params
    skins = %w[Classic DSx].map do |skin|
      {
        name: skin.downcase,
        label: skin,
        checked: params.key?(skin.downcase) || params[:skin]&.casecmp?(skin)
      }
    end
    skins[0][:checked] = true unless skins.find { |s| s[:checked] }

    skins
  end
end
