class AddDateFormatToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :date_format, :string
  end
end
