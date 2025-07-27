class CanonicalRoaster < ApplicationRecord
  has_many :canonical_coffee_bags, dependent: :destroy
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
