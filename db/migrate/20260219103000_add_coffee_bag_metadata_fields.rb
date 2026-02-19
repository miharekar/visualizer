class AddCoffeeBagMetadataFields < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :coffee_bag_metadata_fields, :jsonb
    add_column :coffee_bags, :metadata, :jsonb
  end
end
