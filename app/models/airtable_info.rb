class AirtableInfo < ApplicationRecord
  belongs_to :identity

  def tables
    super.presence || {}
  end

  def update_tables(table_name, **attributes)
    new_tables = tables.dup
    new_tables[table_name] = new_tables[table_name]&.merge(attributes) || attributes
    update!(tables: new_tables)
  end

  def table_fields_for(table_name)
    tables&.dig(table_name, "fields").index_by { |f| f["name"] } || {}
  end
end

# == Schema Information
#
# Table name: airtable_infos
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
