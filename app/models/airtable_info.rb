class AirtableInfo < ApplicationRecord
  class Job < AirtableJob; end

  performs :webhook_refresh

  belongs_to :identity

  def tables
    super.presence || {}
  end

  def update_tables(table_name, **attributes)
    new_tables = tables.dup
    attributes = attributes.deep_stringify_keys
    new_tables[table_name] = new_tables[table_name]&.merge(attributes) || attributes
    update!(tables: new_tables)
  end

  def table_fields_for(table_name)
    tables&.dig(table_name, "fields")&.index_by { |f| f["name"] } || {}
  end

  def webhook_refresh
    user = identity.user
    Airtable::Shots.new(user).webhook_refresh
  rescue Airtable::DataError => e
    if e.matches_error_type?(%w[NOT_FOUND INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND CANNOT_REFRESH_DISABLED_WEBHOOK])
      destroy
    else
      Appsignal.report_error(e) { it.set_tags(user_id: user.id) }
    end
  end
end

# == Schema Information
#
# Table name: airtable_infos
# Database name: primary
#
#  id               :uuid             not null, primary key
#  last_cursor      :integer
#  last_transaction :integer
#  tables           :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  base_id          :string
#  identity_id      :uuid             not null
#  webhook_id       :string
#
# Indexes
#
#  index_airtable_infos_on_identity_id  (identity_id)
#
# Foreign Keys
#
#  fk_rails_...  (identity_id => identities.id)
#
