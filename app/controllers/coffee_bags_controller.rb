class CoffeeBagsController < ApplicationController
  before_action :set_roaster
  before_action :set_coffee_bag, only: %i[edit update destroy remove_image]
  before_action :load_coffee_bags, only: %i[index search]

  def index
  end

  def search
    render :index
  end

  def new
    @coffee_bag = @roaster.coffee_bags.build
  end

  def edit
  end

  def create
    @coffee_bag = @roaster.coffee_bags.build(coffee_bag_params)
    if @coffee_bag.save
      redirect_to roaster_coffee_bags_path(@roaster, format: :html), notice: "#{@coffee_bag.display_name} was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @coffee_bag.update(coffee_bag_params)
      redirect_to roaster_coffee_bags_path(@roaster, format: :html), notice: "#{@coffee_bag.display_name} was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @coffee_bag.destroy!
    redirect_to roaster_coffee_bags_path(@roaster, format: :html), notice: "#{@coffee_bag.display_name} was successfully deleted."
  end

  def remove_image
    @coffee_bag.image.purge
    render turbo_stream: turbo_stream.remove("coffee-bag-image")
  end

  private

  def set_roaster
    @roaster = current_user.roasters.find(params[:roaster_id])
  end

  def set_coffee_bag
    @coffee_bag = @roaster.coffee_bags.find(params[:id])
  end

  def load_coffee_bags
    @coffee_bags = @roaster.coffee_bags.order_by_roast_date
    @coffee_bags = @coffee_bags.where("coffee_bags.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:coffee])}%") if params[:coffee].present?
  end

  def coffee_bag_params
    params.require(:coffee_bag).permit(:name, :roast_date, :roast_level, :country, :region, :farm, :farmer, :variety, :elevation, :processing, :harvest_time, :quality_score, :image)
  end
end
