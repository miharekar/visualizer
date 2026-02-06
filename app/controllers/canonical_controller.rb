class CanonicalController < ApplicationController
  layout false

  def autocomplete_coffee_bags
    if params[:canonical_roaster_id].present?
      @coffee_bags = CanonicalCoffeeBag.search(params[:q]).where(canonical_roaster_id: params[:canonical_roaster_id])
    else
      @coffee_bags = CanonicalCoffeeBag.none
    end
  end

  def autocomplete_roasters
    @roasters = CanonicalRoaster.search(params[:q])
  end
end
