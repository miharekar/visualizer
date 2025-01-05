class Roaster < ApplicationRecord
  include Airtablable
  include Squishable

  after_save_commit :update_shots, if: -> { saved_change_to_name? }

  belongs_to :user
  has_many :coffee_bags, dependent: :destroy
  has_many :shots, through: :coffee_bags

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :filter_by_name, ->(name) { where("LOWER(roasters.name) = ?", name.downcase.squish) }
  scope :order_by_name, -> { order("LOWER(roasters.name)") }
  scope :with_at_least_one_coffee_bag, -> { joins(:coffee_bags).group(:id) }

  squishes :name, :website

  validates :name, presence: true, uniqueness: {scope: :user_id, case_sensitive: false}

  def self.for_user_by_name(user, name, **create_attrs)
    where(user:).filter_by_name(name).first || create(name:, user:, **create_attrs)
  end

  def to_api_json
    attributes.slice(*%w[id name website]).tap do |json|
      json["image_url"] = image&.url if image.attached?
    end
  end

  private

  def update_shots
    ActiveJob.perform_all_later(coffee_bags.pluck(:id).map { |id| RefreshCoffeeBagFieldsOnShotsJob.new(CoffeeBag.new(id:)) })
  end
end

# == Schema Information
#
# Table name: roasters
#
#  id          :uuid             not null, primary key
#  name        :string
#  website     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  airtable_id :string
#  user_id     :uuid             not null
#
# Indexes
#
#  index_roasters_on_airtable_id       (airtable_id)
#  index_roasters_on_user_id_and_name  (user_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
