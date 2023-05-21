# frozen_string_literal: true

class Change < ApplicationRecord
  include Sluggable
  slug_from :title

  has_one_attached :image do |attachable|
    attachable.variant :social, resize_to_limit: [800, 500]
  end
end

# == Schema Information
#
# Table name: changes
#
#  id           :uuid             not null, primary key
#  body         :text
#  excerpt      :string
#  published_at :datetime
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_changes_on_slug  (slug) UNIQUE
#
