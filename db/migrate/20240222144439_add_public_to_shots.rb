class AddPublicToShots < ActiveRecord::Migration[7.1]
  def change
    add_column :shots, :public, :boolean
  end
end
