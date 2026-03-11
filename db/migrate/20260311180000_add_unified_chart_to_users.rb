class AddUnifiedChartToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :unified_chart, :boolean, default: false, null: false
  end
end
