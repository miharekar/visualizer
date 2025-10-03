module Api
  class CoffeeBagsController < Api::BaseController
    before_action :verify_read_access
    before_action :find_roaster

    def index
      coffee_bags = @roaster.coffee_bags.active_first.by_roast_date
      coffee_bags, paging = paginate(coffee_bags)
      render json: {data: coffee_bags.map { {id: it.id, name: it.name} }, paging:}
    end

    def show
      coffee_bag = @roaster.coffee_bags.find(params[:id])
      render json: coffee_bag.to_api_json
    end

    private

    def find_roaster
      @roaster = Current.user.roasters.find(params[:roaster_id])
    end
  end
end
