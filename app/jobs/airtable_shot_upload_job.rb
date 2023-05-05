# frozen_string_literal: true

class AirtableShotUploadJob < ApplicationJob
  queue_as :default

  def perform(shot)
    Airtable::Shot.new(shot.user).upload(shot)
  end
end
