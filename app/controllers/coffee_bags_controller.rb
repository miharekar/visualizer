class CoffeeBagsController < ApplicationController
  before_action :set_coffee_bag, only: %i[show edit update destroy form_for_shot]

  # GET /coffee_bags
  def index
    @coffee_bags = CoffeeBag.all
  end

  # GET /coffee_bags/1
  def show
  end

  # GET /coffee_bags/new
  def new
    @coffee_bag = CoffeeBag.new
  end

  # GET /coffee_bags/1/edit
  def edit
  end

  # POST /coffee_bags
  def create
    @coffee_bag = CoffeeBag.new(coffee_bag_params)

    if @coffee_bag.save
      redirect_to @coffee_bag, notice: "Coffee bag was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /coffee_bags/1
  def update
    if @coffee_bag.update(coffee_bag_params)
      redirect_to @coffee_bag, notice: "Coffee bag was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /coffee_bags/1
  def destroy
    @coffee_bag.destroy!
    redirect_to coffee_bags_url, notice: "Coffee bag was successfully destroyed.", status: :see_other
  end

  def form_for_shot
    @roasters = current_user.roasters.order(:name)
    @roaster = params[:roaster].present? ? current_user.roasters.find(params[:roaster]) : @coffee_bag.roaster
    @coffee_bags = @roaster.coffee_bags.order(roast_date: :desc)

    render layout: false
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_coffee_bag
    @coffee_bag = CoffeeBag.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def coffee_bag_params
    params.require(:coffee_bag).permit(:roaster_id, :name, :roast_date, :roast_level, :country, :region, :farm, :farmer, :variety, :elevation, :processing, :harvest_time, :quality_score)
  end
end
