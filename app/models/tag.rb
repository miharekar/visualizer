class Tag < ApplicationRecord
  include Sluggable
  slug_from :name
  slug_scope_to :user_id

  belongs_to :user
  has_many :shot_tags, dependent: :destroy
  has_many :shots, through: :shot_tags

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: {scope: :user_id, case_sensitive: false}
end

# == Schema Information
#
# Table name: tags
# Database name: primary
#
#  id         :uuid             not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_tags_on_user_id_and_slug  (user_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
