class CanonicalCoffeeBag < ApplicationRecord
  DISPLAY_ATTRIBUTES = %i[name roast_level country region farmer variety elevation processing harvest_time tasting_notes].freeze

  belongs_to :canonical_roaster

  def self.search(term)
    scope = joins(:canonical_roaster)
    term.squish.split.each do |word|
      scope = scope.where("unaccent(canonical_roasters.name) ILIKE unaccent(?)", "%#{word}%")
        .or(scope.where("unaccent(canonical_coffee_bags.name) ILIKE unaccent(?)", "%#{word}%"))
    end
    scope
  end
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
