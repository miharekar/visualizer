# frozen_string_literal: true

class ShareableProfile < ApplicationRecord
  CHARS = ("A".."Z").to_a

  belongs_to :shot

  before_save :set_code

  private

  def set_code
    return if code.present? && persisted?

    loop do
      break if code.present? && !ShareableProfile.exists?(code: code)

      self.code = (0...4).map { CHARS.sample }.join
    end
  end
end

# == Schema Information
#
# Table name: shareable_profiles
#
#  id         :uuid             not null, primary key
#  code       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  shot_id    :uuid             not null
#
# Indexes
#
#  index_shareable_profiles_on_code     (code) UNIQUE
#  index_shareable_profiles_on_shot_id  (shot_id)
#
# Foreign Keys
#
#  fk_rails_...  (shot_id => shots.id)
#
