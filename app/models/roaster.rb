class Roaster < ApplicationRecord
  belongs_to :user
  has_many :coffee_bags, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :by_name, -> { order("LOWER(roasters.name)") }
  scope :with_at_least_one_coffee_bag, -> { joins(:coffee_bags).group(:id) }

  validates :name, presence: true, uniqueness: {scope: :user_id}
end

# == Schema Information
#
# Table name: roasters
#
#  id         :uuid             not null, primary key
#  name       :string
#  website    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_roasters_on_user_id           (user_id)
#  index_roasters_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#