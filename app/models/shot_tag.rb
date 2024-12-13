class ShotTag < ApplicationRecord
  belongs_to :shot
  belongs_to :tag
end

# == Schema Information
#
# Table name: shot_tags
#
#  shot_id :bigint           not null
#  tag_id  :bigint           not null
#
# Indexes
#
#  index_shot_tags_on_tag_id_and_shot_id  (tag_id,shot_id) UNIQUE
#
