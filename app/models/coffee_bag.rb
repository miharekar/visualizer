# frozen_string_literal: true

class CoffeeBag < ApplicationRecord
  belongs_to :coffee
  has_many :shots, dependent: :nullify
end

# == Schema Information
#
# Table name: coffee_bags
#
#  id         :uuid             not null, primary key
#  harvest    :string
#  level      :string
#  quality    :string
#  roast_date :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  coffee_id  :uuid             not null
#
# Indexes
#
#  index_coffee_bags_on_coffee_id  (coffee_id)
#
# Foreign Keys
#
#  fk_rails_...  (coffee_id => coffees.id)
#
