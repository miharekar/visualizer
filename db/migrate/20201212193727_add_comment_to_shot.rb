class AddCommentToShot < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :comment, :text
  end
end
