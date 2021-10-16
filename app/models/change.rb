# frozen_string_literal: true

class Change < ApplicationRecord
end

# == Schema Information
#
# Table name: changes
#
#  id           :uuid             not null, primary key
#  body         :text
#  published_at :datetime
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
