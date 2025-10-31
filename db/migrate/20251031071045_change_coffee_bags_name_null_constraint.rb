class ChangeCoffeeBagsNameNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :coffee_bags, :name, false
  end
end
