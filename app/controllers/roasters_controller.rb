class RoastersController < ApplicationController
  before_action :set_roaster, only: %i[ show edit update destroy ]

  # GET /roasters
  def index
    @roasters = Roaster.by_name
  end

  # GET /roasters/1
  def show
  end

  # GET /roasters/new
  def new
    @roaster = Roaster.new
  end

  # GET /roasters/1/edit
  def edit
  end

  # POST /roasters
  def create
    @roaster = Roaster.new(roaster_params)

    if @roaster.save
      redirect_to @roaster, notice: "Roaster was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /roasters/1
  def update
    if @roaster.update(roaster_params)
      redirect_to @roaster, notice: "Roaster was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /roasters/1
  def destroy
    @roaster.destroy!
    redirect_to roasters_url, notice: "Roaster was successfully destroyed.", status: :see_other
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_roaster
    @roaster = Roaster.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def roaster_params
    params.require(:roaster).permit(:user_id, :name, :website, :image)
  end
end
