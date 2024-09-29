class AddIndexForRoasterAndCoffee < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    enable_extension :pg_trgm
    add_index :shots, :bean_brand, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently
    add_index :shots, :bean_type, opclass: :gin_trgm_ops, using: :gin, algorithm: :concurrently
  end
end
