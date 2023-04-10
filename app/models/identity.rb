# frozen_string_literal: true

class Identity < ApplicationRecord
  belongs_to :user

  validates :uid, :provider, presence: true
  validates :uid, uniqueness: {scope: :provider} # rubocop:disable Rails/UniqueValidationWithoutIndex
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
