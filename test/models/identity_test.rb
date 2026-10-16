require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  test "tokens are encrypted at rest and plaintext rows fail loudly" do
    identity = create(:identity, token: "access_token", refresh_token: "refresh_token")

    stored = Identity.connection.select_rows(Identity.where(id: identity.id).select(:token, :refresh_token).to_sql).sole
    assert_not_includes stored, "access_token"
    assert_not_includes stored, "refresh_token"
    assert_equal "access_token", identity.reload.token

    Identity.where(id: identity.id).update_all("token = 'legacy_token'") # rubocop:disable Rails/SkipsModelValidations
    assert_raises(ActiveRecord::Encryption::Errors::Decryption) { identity.reload.token }
  end
end
