class AddDescriptiveAssessmentToShots < ActiveRecord::Migration[8.0]
  def change
    add_column :shots, :fragrance, :integer
    add_column :shots, :aroma, :integer
    add_column :shots, :flavor, :integer
    add_column :shots, :aftertaste, :integer
    add_column :shots, :acidity, :integer
    add_column :shots, :sweetness, :integer
    add_column :shots, :mouthfeel, :integer
  end
end
