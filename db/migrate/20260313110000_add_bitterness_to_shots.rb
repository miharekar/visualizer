class AddBitternessToShots < ActiveRecord::Migration[8.0]
  def change
    add_column :shots, :bitterness, :integer
  end
end
