# frozen_string_literal: true

class Coffee < ApplicationRecord
  has_many :coffee_bags, dependent: :destroy
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
#  roaster    :string
#  variety    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
