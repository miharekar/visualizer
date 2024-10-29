class CoffeeBagsController < ApplicationController
  before_action :check_premium!
  before_action :set_roaster
  before_action :set_coffee_bag, only: %i[edit update duplicate destroy remove_image]
  before_action :load_coffee_bags, only: %i[index search]
  before_action :load_roasters, only: %i[edit update duplicate]

  def index; end

  def search
    render :index
  end

  def new
    @coffee_bag = @roaster.coffee_bags.build
  end

  def edit; end

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
      redirect_to roaster_coffee_bags_path(@coffee_bag.roaster, format: :html), notice: "#{@coffee_bag.display_name} was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def duplicate
    if params[:roast_date].blank?
      flash.now[:alert] = "Please provide a roast date to duplicate this coffee bag."
      render :edit, status: :unprocessable_entity
    else
      duplicate = @coffee_bag.duplicate(params[:roast_date])
      if duplicate.save
        redirect_to roaster_coffee_bags_path(@roaster, format: :html), notice: "#{@coffee_bag.display_name} was successfully duplicated as #{duplicate.display_name}."
      else
        flash.now[:alert] = "Failed to duplicate coffee bag."
        render :edit, status: :unprocessable_entity
      end
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
    @roaster = Current.user.roasters.find(params[:roaster_id])
  end

  def set_coffee_bag
    @coffee_bag = @roaster.coffee_bags.find(params[:id])
  end

  def load_coffee_bags
    @coffee_bags = @roaster.coffee_bags.order_by_roast_date
    @coffee_bags = @coffee_bags.where("coffee_bags.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:coffee])}%") if params[:coffee].present?
  end

  def load_roasters
    @roasters = Current.user.roasters.order_by_name.includes(:coffee_bags)
  end

  def coffee_bag_params
    cb_params = params.require(:coffee_bag).permit(:name, :roaster_id, :roast_date, :roast_level, :country, :region, :farm, :farmer, :variety, :elevation, :processing, :harvest_time, :quality_score, :image)
    roaster = Current.user.roasters.find_by(id: cb_params[:roaster_id])
    cb_params[:roaster_id] = @roaster.id if roaster.blank?
    cb_params
  end
end
