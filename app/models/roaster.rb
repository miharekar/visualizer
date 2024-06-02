class Roaster < ApplicationRecord
  after_save_commit :update_shots, if: -> { saved_change_to_name? }

  belongs_to :user
  has_many :coffee_bags, dependent: :destroy
  has_many :shots, through: :coffee_bags

  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [200, 200]
  end

  scope :filter_by_name, ->(name) { where("LOWER(roasters.name) = ?", name.downcase) }
  scope :order_by_name, -> { order("LOWER(roasters.name)") }
  scope :with_at_least_one_coffee_bag, -> { joins(:coffee_bags).group(:id) }

  validates :name, presence: true, uniqueness: {scope: :user_id, case_sensitive: false}

  def self.for_user_by_name(user, name)
    where(user:).filter_by_name(name).first || create(name:, user:)
  end

  private

  def update_shots
    update_shot_jobs = shots.map { |shot| RefreshCoffeeBagFieldsForShotJob.new(shot) }
    ActiveJob.perform_all_later(update_shot_jobs)
  end
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
