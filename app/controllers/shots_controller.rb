class ShotsController < ApplicationController
  # GET /shots/1
  def show
    @shot = Shot.find(params[:id])
    @temperature_data, @data_without_temperature = @shot.data.sort_by { |d| d[:label] }.partition { |d| d["label"].include?("Temperature") }
  end

  # GET /shots/new
  def new
    @shot = Shot.new
  end

  # POST /shots
  def create
    shot = ShotParser.new(File.read(params["file"]))
    @shot = Shot.new(start_time: shot.start_time, data: shot.chart_data)

    if @shot.save
      redirect_to @shot, notice: "Shot was successfully created."
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
