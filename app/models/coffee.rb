# frozen_string_literal: true

class Coffee < ApplicationRecord
  belongs_to :roaster
  has_many :coffee_bags, dependent: :destroy

  has_one_attached :image do |attachable|
    attachable.variant :display, resize_to_limit: [1000, 500]
  end
end

# == Schema Information
#
# Table name: coffees
#
#  id         :uuid             not null, primary key
#  altitude   :string
#  country    :string
#  name       :string
#  process    :string
#  producer   :string
#  region     :string
#  variety    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  roaster_id :uuid
#
# Indexes
#
#  index_coffees_on_roaster_id  (roaster_id)
#
# Foreign Keys
#
#  fk_rails_...  (roaster_id => roasters.id)
#
