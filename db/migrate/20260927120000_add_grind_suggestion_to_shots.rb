class AddGrindSuggestionToShots < ActiveRecord::Migration[8.1]
  def change
    add_column :shots, :grind_suggestion, :jsonb
  end
end
