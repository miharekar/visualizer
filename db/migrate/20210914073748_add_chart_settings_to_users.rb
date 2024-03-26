class AddChartSettingsToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :chart_settings, :jsonb
  end
end
