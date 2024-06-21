class CoffeeBag < ApplicationRecord
  DISPLAY_ATTRIBUTES = %i[roast_level country region farm farmer variety elevation processing harvest_time quality_score]

  after_save_commit :update_shots, if: -> { saved_change_to_name? || saved_change_to_roast_date? || saved_change_to_roast_level? }
  after_save_commit :sync_to_airtable

  belongs_to :roaster, touch: true
  has_many :shots, dependent: :nullify
  delegate :user, to: :roaster

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
    attachable.variant :display, resize_to_limit: [1000, 500]
  end

  scope :filter_by_name, ->(name) { where("LOWER(coffee_bags.name) = ?", name.downcase) }
  scope :order_by_roast_date, -> { order("roast_date DESC NULLS LAST") }

  attr_accessor :skip_airtable_sync

  validates :name, presence: true, uniqueness: {scope: %i[roaster_id roast_date], case_sensitive: false}

  def self.for_roaster_by_name_and_date(roaster, name, roast_date, roast_level: nil)
    roast_date = Date.parse(roast_date) rescue nil
    where(roaster:).filter_by_name(name).where(roast_date:).first || create(name:, roaster:, roast_date:, roast_level:)
  end

  def display_name
    roast_date.blank? ? name : "#{name} (#{roast_date.to_fs(:long)})"
  end

  private

  def update_shots
    update_shot_jobs = shots.map { |shot| RefreshCoffeeBagFieldsForShotJob.new(shot) }
    ActiveJob.perform_all_later(update_shot_jobs)
  end

  def sync_to_airtable
    return if skip_airtable_sync || !user.sync_to_airtable?

    AirtableCoffeeBagUploadJob.perform_later(self)
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
