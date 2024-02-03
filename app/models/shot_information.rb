# frozen_string_literal: true

class ShotInformation < ApplicationRecord
  prepend MemoWise
  include Profile
  include LiveParser

  belongs_to :shot

  def extra
    super.presence || {}
  end

  def profile_fields
    super.presence || {}
  end
end

# == Schema Information
#
# Table name: shot_informations
#
#  id             :uuid             not null, primary key
#  brewdata       :jsonb
#  data           :jsonb
#  extra          :jsonb
#  profile_fields :jsonb
#  timeframe      :jsonb
#  shot_id        :uuid             not null
#
# Indexes
#
#  index_shot_informations_on_shot_id  (shot_id)
#
# Foreign Keys
#
#  fk_rails_...  (shot_id => shots.id)
#
