class CoffeeBagsController < ApplicationController
  before_action :set_roaster
  before_action :set_coffee_bag, only: %i[edit update destroy]

  def index
    @coffee_bags = @roaster.coffee_bags.by_roast_date
  end

  def new
    @coffee_bag = @roaster.coffee_bags.build
  end

  def edit
  end

  def create
    @coffee_bag = @roaster.coffee_bags.build(coffee_bag_params)
    if @coffee_bag.save
      redirect_to roaster_coffee_bags_path(@roaster, format: :html), notice: "Coffee bag was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coffee_bag.update(coffee_bag_params)
      redirect_to roaster_coffee_bags_path(@roaster, format: :html), notice: "Coffee bag was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coffee_bag.destroy!
    redirect_to coffee_bags_url, notice: "Coffee bag was successfully destroyed.", status: :see_other
  end

  private

  def set_roaster
    @roaster = current_user.roasters.find(params[:roaster_id])
  end

  def set_coffee_bag
    @coffee_bag = @roaster.coffee_bags.find(params[:id])
  end

  def coffee_bag_params
    params.require(:coffee_bag).permit(:name, :roast_date, :roast_level, :country, :region, :farm, :farmer, :variety, :elevation, :processing, :harvest_time, :quality_score, :image)
  end
end
