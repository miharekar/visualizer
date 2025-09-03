class AddCanonicalRoasterToRoasters < ActiveRecord::Migration[8.0]
  def change
    add_reference :roasters, :canonical_roaster, null: true, foreign_key: true, type: :uuid
  end
end
