class CanonicalCoffeeBagsController < ApplicationController
  def autocomplete
    @coffee_bags = CanonicalCoffeeBag.search(params[:q])
    render layout: false
  end
end
