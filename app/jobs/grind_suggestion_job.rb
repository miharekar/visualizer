class GrindSuggestionJob < ApplicationJob
  def perform(shot)
    shot.suggest_grind_now
  end
end
