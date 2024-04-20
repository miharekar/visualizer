class CoffeeBagsController < ApplicationController
  before_action :set_coffee_bag, only: %i[show edit update destroy shot_form]

  def index
    @coffee_bags = CoffeeBag.all
  end

  def show
  end

  def new
    @coffee_bag = CoffeeBag.new
  end

  def edit
  end

  def create
    @coffee_bag = CoffeeBag.new(coffee_bag_params)

    if @coffee_bag.save
      redirect_to @coffee_bag, notice: "Coffee bag was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coffee_bag.update(coffee_bag_params)
      redirect_to @coffee_bag, notice: "Coffee bag was successfully updated.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coffee_bag.destroy!
    redirect_to coffee_bags_url, notice: "Coffee bag was successfully destroyed.", status: :see_other
  end

  def shot_form
    @roasters = current_user.roasters.by_name
    @roaster = params[:roaster].present? ? current_user.roasters.find(params[:roaster]) : @coffee_bag.roaster
    @coffee_bags = @roaster.coffee_bags.by_roast_date

    render layout: false
  end

  private

  def set_coffee_bag
    @coffee_bag = CoffeeBag.find(params[:id])
  end

  def coffee_bag_params
    params.require(:coffee_bag).permit(:roaster_id, :name, :roast_date, :roast_level, :country, :region, :farm, :farmer, :variety, :elevation, :processing, :harvest_time, :quality_score)
  end
end
