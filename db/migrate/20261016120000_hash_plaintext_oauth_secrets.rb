class HashPlaintextOauthSecrets < ActiveRecord::Migration[8.1]
  def up
    hash_plaintext :oauth_access_grants, :token
    hash_plaintext :oauth_access_tokens, :token
    hash_plaintext :oauth_access_tokens, :refresh_token
    hash_plaintext :oauth_access_tokens, :previous_refresh_token
    hash_plaintext :oauth_applications, :secret
  end

  private

  def hash_plaintext(table, column)
    execute "UPDATE #{table} SET #{column} = encode(sha256(convert_to(#{column}, 'UTF8')), 'hex') WHERE #{column} <> '' AND length(#{column}) <> 64"
  end
end
