class ShotInformation < ApplicationRecord
  prepend MemoWise
  include Profile

  belongs_to :shot, inverse_of: :information

  def extra
    super || {}
  end

  def profile_fields
    super || {}
  end

  def brewdata
    super || {}
  end

  def has_chart_data?
    !beanconqueror?
  end

  def beanconqueror?
    parser_name == "beanconqueror"
  end

  def parser_name
    parser.split("::").last.downcase
  end

  def parser
    brewdata.fetch("parser", "Parsers::DecentTcl")
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
