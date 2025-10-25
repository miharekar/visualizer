class DropdownValue < ApplicationRecord
  VALID_KINDS = %w[grinder_model bean_brand bean_type].freeze

  belongs_to :user
  validates :kind, presence: true, inclusion: {in: VALID_KINDS}
  validates :value, presence: true, uniqueness: {scope: %i[user_id kind]}

  scope :for, ->(user, kind) { where(user:, kind:) }
  scope :visible, -> { where(hidden_at: nil) }

  def toggle!
    update!(hidden_at: hidden_at? ? nil : Time.current)
  end
end

# == Schema Information
#
# Table name: dropdown_values
# Database name: primary
#
#  id         :uuid             not null, primary key
#  hidden_at  :datetime
#  kind       :string
#  value      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_dropdown_values_on_user_id                     (user_id)
#  index_dropdown_values_on_user_id_and_kind_and_value  (user_id,kind,value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
