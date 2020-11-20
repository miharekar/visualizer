class ShotsController < ApplicationController
  # GET /shots/1
  def show
    @shot = Shot.find(params[:id])
    @temperature_data, @main_data = @shot.chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("Temperature") }
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
      redirect_to @shot
    else
      render :new
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def shot_params
    params.permit(:file)
  end
end
