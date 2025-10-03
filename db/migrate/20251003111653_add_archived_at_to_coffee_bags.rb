class AddArchivedAtToCoffeeBags < ActiveRecord::Migration[8.1]
  def change
    add_column :coffee_bags, :archived_at, :datetime
  end
end
