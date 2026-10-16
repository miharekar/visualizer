class RemoveGrindSuggestion < ActiveRecord::Migration[8.1]
  def change
    remove_column :shots, :grind_suggestion, :jsonb
    remove_column :coffee_bags, :grind_suggestion, :jsonb
  end
end
