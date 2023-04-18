# frozen_string_literal: true

class AirtableInfo < ApplicationRecord
  belongs_to :identity
end

# == Schema Information
#
# Table name: airtable_infos
#
#  id           :uuid             not null, primary key
#  table_fields :jsonb
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  base_id      :string
#  identity_id  :uuid             not null
#  table_id     :string
#  webhook_id   :string
#
# Indexes
#
#  index_airtable_infos_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
