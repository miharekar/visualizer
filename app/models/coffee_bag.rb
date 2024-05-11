class CoffeeBag < ApplicationRecord
  belongs_to :roaster, touch: true
  has_many :shots, dependent: :nullify

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :by_roast_date, -> { order("roast_date DESC NULLS LAST") }

  validates :name, presence: true

  def display_name
    roast_date.blank? ? name : "#{name} (#{roast_date.strftime("%d %b %y")})"
  end
end

# == Schema Information
#
# Table name: coffee_bags
#
#  id            :uuid             not null, primary key
#  country       :string
#  elevation     :string
#  farm          :string
#  farmer        :string
#  harvest_time  :string
#  name          :string
#  processing    :string
#  quality_score :string
#  region        :string
#  roast_date    :date
#  roast_level   :string
#  variety       :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  roaster_id    :uuid             not null
#
# Indexes
#
#  index_coffee_bags_on_roaster_id  (roaster_id)
#
# Foreign Keys
#
#  fk_rails_...  (roaster_id => roasters.id)
#
