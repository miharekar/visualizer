class AddGithubToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :github, :string
  end
end
