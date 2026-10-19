class AddTrigramIndexesForProfileTitleAndGrinderModel < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :shots, :profile_title, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, if_not_exists: true
    add_index :shots, :grinder_model, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, if_not_exists: true
  end
end
