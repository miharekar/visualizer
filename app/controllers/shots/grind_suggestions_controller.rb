module Shots
  class GrindSuggestionsController < ApplicationController
    before_action :require_authentication
    before_action :check_admin!

    def create
      @shot = Current.user.shots.find(params.expect(:shot_id))
      @shot.suggest_grind_now
      render turbo_stream: turbo_stream.replace(helpers.dom_id(@shot, :grind_suggestion), partial: "shots/grind_suggestion", locals: {shot: @shot})
    end
  end
end
