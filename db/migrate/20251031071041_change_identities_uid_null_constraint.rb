class ChangeIdentitiesUidNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :identities, :uid, false
  end
end
