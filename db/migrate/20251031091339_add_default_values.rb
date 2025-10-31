class AddDefaultValues < ActiveRecord::Migration[8.1]
  def change
    # Users booleans
    change_column_default :users, :admin, from: nil, to: false
    change_column_default :users, :beta, from: nil, to: false
    change_column_default :users, :coffee_management_enabled, from: nil, to: false
    change_column_default :users, :developer, from: nil, to: false
    change_column_default :users, :hide_shot_times, from: nil, to: false
    change_column_default :users, :supporter, from: nil, to: false

    change_column_default :shots, :public, from: nil, to: false
  end
end
