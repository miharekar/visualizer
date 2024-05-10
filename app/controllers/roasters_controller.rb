class RoastersController < ApplicationController
  before_action :check_premium!
  before_action :set_roaster, only: %i[ show edit update destroy ]
  before_action :load_roasters, only: %i[index search]

  def index
  end

  def search
    render :index
  end

  def show
  end

  def new
    @roaster = Roaster.new
  end

  def edit
  end

  def create
    @roaster = Roaster.new(roaster_params)

    if @roaster.save
      redirect_to @roaster, notice: "Roaster was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @roaster.update(roaster_params)
      redirect_to @roaster, notice: "Roaster was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @roaster.destroy!
    redirect_to roasters_url, notice: "Roaster was successfully destroyed.", status: :see_other
  end

  private

  def set_roaster
    @roaster = Roaster.find(params[:id])
  end

  def load_roasters
    # include coffee bags with attached images
    @roasters = current_user.roasters.by_name.includes(:coffee_bags)
    @roasters = @roasters.where("roasters.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:roaster])}%") if params[:roaster].present?
    @roasters = @roasters.joins(:coffee_bags).where("coffee_bags.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:coffee])}%") if params[:coffee].present?
  end

  def roaster_params
    params.require(:roaster).permit(:user_id, :name, :website, :image)
  end
end
