module Api
  class CanonicalCoffeeBagsController < Api::BaseController
    def index
      coffee_bags = CanonicalCoffeeBag.search(params[:q].to_s).includes(:canonical_roaster)
      coffee_bags = coffee_bags.where(canonical_roaster_id: params[:canonical_roaster_id]) if params[:canonical_roaster_id].present?
      coffee_bags = coffee_bags.order("canonical_coffee_bags.name")
      coffee_bags, paging = paginate(coffee_bags)
      render json: {data: coffee_bags.map { coffee_bag_json(it) }, paging:}
    end

    private

    def coffee_bag_json(coffee_bag)
      coffee_bag.attributes.slice("id", "canonical_roaster_id", "name", "url", *CanonicalCoffeeBag::DISPLAY_ATTRIBUTES).tap do |json|
        json["canonical_roaster_name"] = coffee_bag.canonical_roaster.name
      end
    end
  end
end
