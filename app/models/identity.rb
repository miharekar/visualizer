class Identity < ApplicationRecord
  include Lockable

  belongs_to :user
  has_one :airtable_info, dependent: :destroy

  validates :uid, :provider, presence: true
  validates :uid, uniqueness: {scope: :provider}

  scope :by_provider, ->(provider) { where(provider:) }

  def valid_token?
    expires_at.nil? || expires_at.future?
  end

  def refresh_token!
    with_lock!(refresh_token_key) do
      next if valid_token?

      new_token = OAuth2::AccessToken.new(strategy.client, token, {expires_at: expires_at.to_i, refresh_token:})
      new_token = new_token.refresh!
      update!(token: new_token.token, refresh_token: new_token.refresh_token, expires_at: Time.zone.at(new_token.expires_at))
      AirtableUploadAllJob.set(wait: 2.minutes).perform_later(user) if airtable?
    end
  rescue OAuth2::Error => e
    if JSON.parse(e.body)["error"] == "invalid_grant"
      Appsignal.report_error(e) do |transaction|
        transaction.set_tags(user_id:)
      end
      destroy!
    end

    raise
  end

  def airtable?
    provider == "airtable"
  end

  private

  def refresh_token_key
    "#{provider}:refreshing_token:#{id}"
  end

  def strategy
    case provider
    when "airtable"
      OmniAuth::Strategies::Airtable.new(
        nil,
        Rails.application.credentials.dig(:airtable, :client_id),
        Rails.application.credentials.dig(:airtable, :client_secret)
      )
    else
      raise "Unknown provider: #{provider}"
    end
  end
end

# == Schema Information
#
# Table name: identities
# Database name: primary
#
#  id            :uuid             not null, primary key
#  blob          :jsonb
#  expires_at    :datetime
#  provider      :string           not null
#  refresh_token :string
#  token         :string
#  uid           :string           not null
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
