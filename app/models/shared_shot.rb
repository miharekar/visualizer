# frozen_string_literal: true

class SharedShot < ApplicationRecord
  CHARS = ("A".."Z").to_a

  belongs_to :shot
  belongs_to :user, optional: true

  before_save :set_code

  private

  def set_code
    return if code.present? && persisted?

    loop do
      break if code.present? && !SharedShot.exists?(code:)

      self.code = (0...4).map { CHARS.sample }.join
    end
  end
end

# == Schema Information
#
# Table name: shared_shots
#
#  id         :uuid             not null, primary key
#  code       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  shot_id    :uuid             not null
#  user_id    :uuid
#
# Indexes
#
#  index_shared_shots_on_code     (code) UNIQUE
#  index_shared_shots_on_shot_id  (shot_id)
#  index_shared_shots_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (shot_id => shots.id)
#  fk_rails_...  (user_id => users.id)
#
