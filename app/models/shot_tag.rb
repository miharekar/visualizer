class ShotTag < ApplicationRecord
  belongs_to :shot
  belongs_to :tag

  validates :shot_id, uniqueness: {scope: :tag_id}
end

# == Schema Information
#
# Table name: shot_tags
#
#  shot_id :uuid             not null
#  tag_id  :uuid             not null
#
# Indexes
#
#  index_shot_tags_on_shot_id             (shot_id)
#  index_shot_tags_on_tag_id              (tag_id)
#  index_shot_tags_on_tag_id_and_shot_id  (tag_id,shot_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shot_id => shots.id)
#  fk_rails_...  (tag_id => tags.id)
#
