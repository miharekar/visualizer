# frozen_string_literal: true

class Identity < ApplicationRecord
  belongs_to :user
  has_one :airtable_info, dependent: :destroy

  validates :uid, :provider, presence: true
  validates :uid, uniqueness: {scope: :provider} # rubocop:disable Rails/UniqueValidationWithoutIndex

  scope :by_provider, ->(provider) { where(provider:) }

  def ensure_valid_token!
    return if expires_at.nil? || expires_at.future?

    devise_config = Devise.omniauth_configs[provider.to_sym]
    strategy = devise_config.strategy_class.new(nil, *devise_config.args)
    new_token = OAuth2::AccessToken.new(strategy.client, token, {expires_at: expires_at.to_i, refresh_token:})
    new_token = new_token.refresh!
    self.token = new_token.token
    self.refresh_token = new_token.refresh_token
    self.expires_at = Time.zone.at(new_token.expires_at)
    save!
  end
end

# == Schema Information
#
# Table name: identities
#
#  id            :uuid             not null, primary key
#  blob          :jsonb
#  expires_at    :datetime
#  provider      :string
#  refresh_token :string
#  token         :string
#  uid           :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  user_id       :uuid             not null
#
# Indexes
#
#  index_identities_on_provider_and_uid  (provider,uid) UNIQUE
#  index_identities_on_user_id           (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
