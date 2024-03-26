class FillAutocompleteValuesJob < ApplicationJob
  queue_as :low

  def perform
    CommunityController::FILTERS.each do |filter, options|
      next if filter == :user || options[:autocomplete].nil?

      Rails.cache.write(
        "unique_values_for_#{filter}",
        Shot.visible.distinct.where.not(filter => [nil, ""]).pluck(filter).filter_map { |s| s.strip.presence }.uniq(&:downcase).sort_by(&:downcase)
      )
    end
  end
end
