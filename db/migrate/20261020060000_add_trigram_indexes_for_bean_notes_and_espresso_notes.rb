class AddTrigramIndexesForBeanNotesAndEspressoNotes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :shots, :bean_notes, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, if_not_exists: true
    add_index :shots, :espresso_notes, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently, if_not_exists: true
  end
end
