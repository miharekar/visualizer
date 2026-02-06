class CoffeeBagsController < ApplicationController
  include Paginatable

  before_action :require_authentication
  before_action :check_premium!
  before_action :set_coffee_bag, only: %i[edit update duplicate destroy remove_image archive restore freeze defrost]
  before_action :load_coffee_bags, only: %i[index search]
  before_action :load_roasters, only: %i[new edit]

  def index; end

  def search
    @replace = true
    render :index
  end

  def new
    @coffee_bag = Current.user.coffee_bags.build(roaster_id: params[:roaster_id])
  end

  def edit; end

  def create
    @coffee_bag = Current.user.coffee_bags.build(coffee_bag_params)
    if @coffee_bag.save
      redirect_to coffee_bags_path(format: :html), notice: "#{@coffee_bag.display_name} was created."
    else
      load_roasters
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @coffee_bag.update(coffee_bag_params)
      redirect_to coffee_bags_path(format: :html), notice: "#{@coffee_bag.display_name} was updated."
    else
      load_roasters
      render :edit, status: :unprocessable_content
    end
  end

  def duplicate
    if params[:roast_date].blank?
      flash.now[:alert] = "Please provide a roast date to duplicate this coffee bag."
      load_roasters
      render :edit, status: :unprocessable_content
    else
      duplicate = @coffee_bag.duplicate(params[:roast_date])
      if duplicate.save
        redirect_to coffee_bags_path(format: :html), notice: "#{@coffee_bag.display_name} was duplicated as #{duplicate.display_name}."
      else
        flash.now[:alert] = "Failed to duplicate coffee bag."
        load_roasters
        render :edit, status: :unprocessable_content
      end
    end
  end

  def remove_image
    @coffee_bag.image.purge
    render turbo_stream: turbo_stream.remove("coffee-bag-image")
  end

  def scrape_info
    Rails.logger.info "Scraping coffee bag info for #{params[:url]} by #{Current.user.id}"
    info = CoffeeBagScraper.new.get_info(params[:url])

    if info && info[:error].blank?
      render json: info
    else
      error = info[:error].presence || "Could not extract information from URL"
      render json: {error:}, status: :unprocessable_content
    end
  end

  def destroy
    @coffee_bag.destroy!
    redirect_to coffee_bags_path(**params.permit(:roaster, :coffee), format: :html), notice: "#{@coffee_bag.display_name} was deleted."
  end

  def archive
    @coffee_bag.update(archived_at: Time.current)

    respond_to do
      it.turbo_stream { render turbo_stream: turbo_stream.replace(@coffee_bag) }
      it.html { redirect_to coffee_bags_path(**params.permit(:roaster, :coffee), format: :html), notice: "#{@coffee_bag.display_name} was archived." }
    end
  end

  def restore
    @coffee_bag.update(archived_at: nil)

    respond_to do
      it.turbo_stream { render turbo_stream: turbo_stream.replace(@coffee_bag) }
      it.html { redirect_to coffee_bags_path(**params.permit(:roaster, :coffee), format: :html), notice: "#{@coffee_bag.display_name} was restored." }
    end
  end

  def freeze
    @coffee_bag.update(frozen_date: Date.current, defrosted_date: nil)

    respond_to do
      it.turbo_stream { render turbo_stream: turbo_stream.replace(@coffee_bag) }
      it.html { redirect_to coffee_bags_path(**params.permit(:roaster, :coffee), format: :html), notice: "#{@coffee_bag.display_name} was frozen." }
    end
  end

  def defrost
    @coffee_bag.update(defrosted_date: Date.current)

    respond_to do
      it.turbo_stream { render turbo_stream: turbo_stream.replace(@coffee_bag) }
      it.html { redirect_to coffee_bags_path(**params.permit(:roaster, :coffee), format: :html), notice: "#{@coffee_bag.display_name} was defrosted." }
    end
  end

  private

  def set_coffee_bag
    @coffee_bag = Current.user.coffee_bags.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to coffee_bags_path, alert: "Coffee bag not found"
  end

  def load_coffee_bags
    @coffee_bags = Current.user.coffee_bags.active_first.by_roast_date.includes(:roaster).with_attached_image
    @coffee_bags = @coffee_bags.where(roaster_id: params[:roaster_id]) if params[:roaster_id].present?
    @coffee_bags = @coffee_bags.where("roasters.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:roaster])}%") if params[:roaster].present?
    @coffee_bags = @coffee_bags.where("coffee_bags.name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:coffee])}%") if params[:coffee].present?
    @coffee_bags, @offset = paginate_with_offset(@coffee_bags, items: 24, offset: params[:offset].to_i)
  end

  def load_roasters
    @roasters = Current.user.roasters.order_by_name.includes(:coffee_bags)
  end

  def coffee_bag_params
    cb_params = params.expect(coffee_bag: %i[name url canonical_coffee_bag_id roast_date frozen_date defrosted_date notes image] + CoffeeBag::DISPLAY_ATTRIBUTES)
    cb_params[:roaster_id] = Current.user.roasters.find_by(id: params.dig(:coffee_bag, :roaster_id))&.id
    cb_params
  end
end
