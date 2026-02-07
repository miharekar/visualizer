module Api
  class CoffeeBagsController < Api::BaseController
    before_action :check_premium!, only: %i[create update destroy]
    before_action :verify_read_access, only: %i[index show]
    before_action :verify_write_access, only: %i[create update destroy]
    before_action :load_coffee_bag, only: %i[show update destroy]

    def index
      coffee_bags = Current.user.coffee_bags.active_first.by_roast_date
      coffee_bags = coffee_bags.where(roaster_id: params[:roaster_id]) if params[:roaster_id].present?
      coffee_bags, paging = paginate(coffee_bags)
      render json: {data: coffee_bags.map { {id: it.id, name: it.name} }, paging:}
    end

    def show
      render json: @coffee_bag.to_api_json
    end

    def create
      coffee_bag = Current.user.coffee_bags.build(coffee_bag_params)
      if coffee_bag.save
        render json: coffee_bag.to_api_json, status: :created
      else
        render json: {error: coffee_bag.errors.full_messages.join(", ")}, status: :unprocessable_content
      end
    end

    def update
      if @coffee_bag.update(coffee_bag_params)
        render json: @coffee_bag.to_api_json
      else
        render json: {error: @coffee_bag.errors.full_messages.join(", ")}, status: :unprocessable_content
      end
    end

    def destroy
      @coffee_bag.destroy!
      render json: {success: true}
    end

    private

    def load_coffee_bag
      @coffee_bag = Current.user.coffee_bags.find_by(id: params[:id])
      render json: {error: "Coffee bag not found"}, status: :not_found unless @coffee_bag
    end

    def coffee_bag_params
      cb_params = params.expect(coffee_bag: %i[name url canonical_coffee_bag_id roast_date frozen_date defrosted_date notes roaster_id] + CoffeeBag::DISPLAY_ATTRIBUTES)
      return cb_params if params.dig(:coffee_bag, :roaster_id).blank?

      cb_params[:roaster_id] = Current.user.roasters.find_by(id: params.dig(:coffee_bag, :roaster_id))&.id
      cb_params
    end
  end
end
