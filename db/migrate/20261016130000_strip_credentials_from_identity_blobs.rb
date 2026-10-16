class StripCredentialsFromIdentityBlobs < ActiveRecord::Migration[8.1]
  def up
    execute "UPDATE identities SET blob = blob - 'credentials'"
  end
end
