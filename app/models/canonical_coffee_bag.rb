class CanonicalCoffeeBag < ApplicationRecord
  belongs_to :canonical_roaster
end

# == Schema Information
#
# Table name: canonical_coffee_bags
#
#  id                   :uuid             not null, primary key
#  country              :string
#  elevation            :string
#  farmer               :string
#  harvest_time         :string
#  name                 :string
#  processing           :string
#  region               :string
#  roast_level          :string
#  tasting_notes        :string
#  url                  :string
#  variety              :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  canonical_roaster_id :uuid             not null
#  loffee_labs_id       :string
#
# Indexes
#
#  index_canonical_coffee_bags_on_canonical_roaster_id  (canonical_roaster_id)
#
# Foreign Keys
#
#  fk_rails_...  (canonical_roaster_id => canonical_roasters.id)
#
