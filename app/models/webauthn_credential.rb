class WebauthnCredential < ApplicationRecord
  belongs_to :user

  validates :external_id, :public_key, :nickname, :sign_count, presence: true
  validates :external_id, uniqueness: true
  validates :sign_count, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: (2**32) - 1}
end

# == Schema Information
#
# Table name: webauthn_credentials
# Database name: primary
#
#  id           :uuid             not null, primary key
#  last_used_at :datetime
#  nickname     :string           not null
#  public_key   :string           not null
#  sign_count   :integer          default(0), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  external_id  :string           not null
#  user_id      :uuid             not null
#
# Indexes
#
#  index_webauthn_credentials_on_external_id  (external_id) UNIQUE
#  index_webauthn_credentials_on_user_id      (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
