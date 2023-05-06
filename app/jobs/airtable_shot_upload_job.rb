# frozen_string_literal: true

class AirtableShotUploadJob < ApplicationJob
  queue_as :default

  def perform(shot)
    Airtable::Shots.new(shot.user).upload(shot)
  end
end
