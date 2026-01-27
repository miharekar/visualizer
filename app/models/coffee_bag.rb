class CoffeeBag < ApplicationRecord
  include Airtablable
  include Squishable

  DISPLAY_ATTRIBUTES = %w[roast_level country region farm farmer variety elevation processing harvest_time quality_score tasting_notes place_of_purchase].freeze

  belongs_to :roaster, touch: true
  belongs_to :canonical_coffee_bag, optional: true
  has_one :user, through: :roaster
  has_many :shots, dependent: :nullify

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200], format: :jpeg, saver: {strip: true}
    attachable.variant :display, resize_to_limit: [1000, 500], format: :jpeg, saver: {strip: true}
  end

  validates :name, presence: true, uniqueness: {scope: %i[roaster_id roast_date], case_sensitive: false} # rubocop:disable Rails/UniqueValidationWithoutIndex

  after_save_commit :update_shots, if: -> { saved_changes.keys.intersect?(%w[name roast_date roast_level roaster_id]) }

  scope :filter_by_name, ->(name) { where("LOWER(coffee_bags.name) = ?", name.downcase.squish) }
  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }
  scope :active_first, -> { order(Arel.sql("archived_at IS NOT NULL")) }
  scope :by_roast_date, -> { order("roast_date DESC NULLS LAST") }
  scope :for_user, ->(user) { joins(:roaster).where(roasters: {user:}) }

  squishes(*%i[country elevation farm farmer harvest_time name processing quality_score region roast_level url variety tasting_notes place_of_purchase])

  def self.for_roaster_by_name_and_date(roaster, name, roast_date, **create_attrs)
    where(roaster:).filter_by_name(name).where(roast_date:).first || create(name:, roaster:, roast_date:, **create_attrs)
  end

  def display_name
    roast_date.blank? ? name : "#{name} (#{roast_date.to_fs(:long)})"
  end

  def full_display_name
    details = []
    details << roast_date.to_fs(:long) if roast_date.present?
    details << "Archived" if archived?
    suffix = details.any? ? " (#{details.join(", ")})" : ""
    "#{roaster.name}: #{name}#{suffix}"
  end

  def duplicate(roast_date)
    dup.tap { |d| d.roast_date = roast_date }
  end

  def to_api_json
    attribute_names = CoffeeBag::DISPLAY_ATTRIBUTES + %w[id name roast_date url archived_at notes]
    attributes.slice(*attribute_names).tap do |json|
      json["image_url"] = image&.url if image.attached?
    end
  end

  def archived?
    archived_at.present?
  end

  private

  def update_shots
    RefreshCoffeeBagFieldsOnShotsJob.perform_later(self)
  end
end

# == Schema Information
#
# Table name: coffee_bags
# Database name: primary
#
#  id                      :uuid             not null, primary key
#  archived_at             :datetime
#  country                 :string
#  elevation               :string
#  farm                    :string
#  farmer                  :string
#  harvest_time            :string
#  name                    :string           not null
#  notes                   :text
#  place_of_purchase       :string
#  processing              :string
#  quality_score           :string
#  region                  :string
#  roast_date              :date
#  roast_level             :string
#  tasting_notes           :string
#  url                     :string
#  variety                 :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  airtable_id             :string
#  canonical_coffee_bag_id :uuid
#  roaster_id              :uuid             not null
#
# Indexes
#
#  index_coffee_bags_on_airtable_id              (airtable_id)
#  index_coffee_bags_on_canonical_coffee_bag_id  (canonical_coffee_bag_id)
#  index_coffee_bags_on_roaster_id               (roaster_id)
#
# Foreign Keys
#
#  fk_rails_...  (canonical_coffee_bag_id => canonical_coffee_bags.id)
#  fk_rails_...  (roaster_id => roasters.id)
#
