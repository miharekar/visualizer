# frozen_string_literal: true

class Roaster < ApplicationRecord
  has_many :coffees

  has_one_attached :logo do |attachable|
    attachable.variant :display, resize_to_limit: [300, 300]
  end
end

# == Schema Information
#
# Table name: roasters
#
#  id         :uuid             not null, primary key
#  country    :string
#  name       :string
#  website    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
