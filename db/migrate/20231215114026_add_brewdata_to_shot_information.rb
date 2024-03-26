class AddBrewdataToShotInformation < ActiveRecord::Migration[7.1]
  def change
    add_column :shot_informations, :brewdata, :jsonb
  end
end
