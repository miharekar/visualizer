class CanonicalController < ApplicationController
  layout false

  def autocomplete_coffee_bags
    @coffee_bags = CanonicalCoffeeBag.search(params[:q])
    @coffee_bags = @coffee_bags.where(canonical_roaster_id: params[:roaster_id]) if params[:roaster_id].present?
  end

  def autocomplete_roasters
    @roasters = CanonicalRoaster.search(params[:q])
  end
end
