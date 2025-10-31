class ChangeWebauthnCredentialsNicknameNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :webauthn_credentials, :nickname, false
  end
end
