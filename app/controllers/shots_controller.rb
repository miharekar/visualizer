class ShotsController < ApplicationController
  before_action :set_shot, only: [:show]

  # GET /shots/1
  def show
    @shot = Shot.find(params[:id])
  end

  # POST /shots
  def create
    @shot = Shot.new(shot_params)

    if @shot.save
      redirect_to @shot, notice: "Shot was successfully created."
    else
      render :new
    end
  end

  private

  # Only allow a trusted parameter "white list" through.
  def shot_params
    params.require(:shot).permit(:start_time, :data)
  end
end
