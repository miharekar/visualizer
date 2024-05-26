class CoffeeBag < ApplicationRecord
  belongs_to :roaster, touch: true
  has_many :shots, dependent: :nullify

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :by_roast_date, -> { order("roast_date DESC NULLS LAST") }

  validates :name, presence: true

  def self.for_roaster_and_shot(roaster, shot)
    roast_date = Date.parse(shot.roast_date) rescue nil
    roaster.coffee_bags.find_or_create_by(name: shot.bean_type, roast_date:) do |bag|
      bag.roast_level = shot.roast_level
    end
  end

  def display_name
    roast_date.blank? ? name : "#{name} (#{roast_date.to_fs(:long)})"
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
