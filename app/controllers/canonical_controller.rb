class CanonicalController < ApplicationController
  layout false

  def autocomplete_coffee_bags
    @coffee_bags = CanonicalCoffeeBag.search(params[:q])
  end

  def autocomplete_roasters
    @roasters = CanonicalRoaster.search(params[:q])
  end
end
