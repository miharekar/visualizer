# frozen_string_literal: true

class Changelog < ApplicationRecord
end

# == Schema Information
#
# Table name: changelogs
#
#  id           :uuid             not null, primary key
#  body         :text
#  published_at :datetime
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
