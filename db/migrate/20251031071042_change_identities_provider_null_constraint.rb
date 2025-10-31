class ChangeIdentitiesProviderNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :identities, :provider, false
  end
end
