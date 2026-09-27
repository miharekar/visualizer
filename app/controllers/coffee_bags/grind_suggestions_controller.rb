module CoffeeBags
  class GrindSuggestionsController < ApplicationController
    before_action :require_authentication
    before_action :check_admin!

    def create
      @coffee_bag = Current.user.coffee_bags.find(params.expect(:coffee_bag_id))
      @coffee_bag.suggest_grind
      render turbo_stream: turbo_stream.replace(helpers.dom_id(@coffee_bag, :grind_suggestion), partial: "coffee_bags/grind_suggestion", locals: {coffee_bag: @coffee_bag})
    end
  end
end
