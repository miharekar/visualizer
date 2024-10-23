class CoffeeBag < ApplicationRecord
  include Airtablable

  DISPLAY_ATTRIBUTES = %i[roast_level country region farm farmer variety elevation processing harvest_time quality_score].freeze

  after_save_commit :update_shots, if: -> { saved_changes.keys.intersect?(%w[name roast_date roast_level roaster_id]) }

  belongs_to :roaster, touch: true
  has_many :shots, dependent: :nullify
  delegate :user, to: :roaster

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :display, resize_to_limit: [1000, 500]
  end

  scope :filter_by_name, ->(name) { where("LOWER(coffee_bags.name) = ?", name.downcase) }
  scope :order_by_roast_date, -> { order("roast_date DESC NULLS LAST") }

  validates :name, presence: true, uniqueness: {scope: %i[roaster_id roast_date], case_sensitive: false} # rubocop:disable Rails/UniqueValidationWithoutIndex

  def self.for_roaster_by_name_and_date(roaster, name, roast_date, **create_attrs)
    where(roaster:).filter_by_name(name).where(roast_date:).first || create(name:, roaster:, roast_date:, **create_attrs)
  end

  def display_name
    roast_date.blank? ? name : "#{name} (#{roast_date.to_fs(:long)})"
  end

  private

  def update_shots
    RefreshCoffeeBagFieldsOnShotsJob.perform_later(self)
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
#  airtable_id   :string
#  roaster_id    :uuid             not null
#
# Indexes
#
#  index_coffee_bags_on_airtable_id  (airtable_id)
#  index_coffee_bags_on_roaster_id   (roaster_id)
#
# Foreign Keys
#
#  fk_rails_...  (roaster_id => roasters.id)
#
