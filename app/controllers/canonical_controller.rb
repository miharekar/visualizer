class CanonicalController < ApplicationController
  layout false

  def autocomplete_coffee_bags
    if params[:canonical_roaster_id].blank? && params[:require_roaster] == "true"
      @coffee_bags = CanonicalCoffeeBag.none
    else
      @coffee_bags = CanonicalCoffeeBag.search(params[:q])
      @coffee_bags = @coffee_bags.where(canonical_roaster_id: params[:canonical_roaster_id]) if params[:canonical_roaster_id].present?
    end
  end

  def autocomplete_roasters
    @roasters = CanonicalRoaster.search(params[:q])
  end
end
