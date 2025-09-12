class CanonicalRoaster < ApplicationRecord
  has_many :canonical_coffee_bags, dependent: :destroy
  has_many :roasters, dependent: :nullify

  def self.search(term)
    words = term.squish.split
    return none if words.empty?

    scope = all
    words.each do |word|
      scope = scope.where("unaccent(canonical_roasters.name) ILIKE unaccent(?)", "%#{word}%")
    end
    scope
  end
end

# == Schema Information
#
# Table name: canonical_roasters
#
#  id             :uuid             not null, primary key
#  address        :string
#  country        :string
#  name           :string
#  website        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  loffee_labs_id :string
#
