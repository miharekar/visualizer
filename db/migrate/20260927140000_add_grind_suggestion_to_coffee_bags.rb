class AddGrindSuggestionToCoffeeBags < ActiveRecord::Migration[8.1]
  def change
    add_column :coffee_bags, :grind_suggestion, :jsonb
  end
end
