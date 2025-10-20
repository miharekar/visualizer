class ShotTag < ApplicationRecord
  self.primary_key = %i[shot_id tag_id]

  belongs_to :shot
  belongs_to :tag

  validates :shot_id, uniqueness: {scope: :tag_id}
end

# == Schema Information
#
# Table name: shot_tags
# Database name: primary
#
#  shot_id :uuid             not null, primary key
#  tag_id  :uuid             not null, primary key
#
# Indexes
#
#  index_shot_tags_on_shot_id             (shot_id)
#  index_shot_tags_on_tag_id_and_shot_id  (tag_id,shot_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shot_id => shots.id)
#  fk_rails_...  (tag_id => tags.id)
#
