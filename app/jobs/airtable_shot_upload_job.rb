# frozen_string_literal: true

class AirtableShotUploadJob < ApplicationJob
  queue_as :default

  def perform(shot)
    Airtable::Shots.new(shot.user).upload(shot)
  rescue Airtable::DataError => e
    json = JSON.parse(e.message)
    if json["error"]["type"] == "INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND"
      shot.user.identities.by_provider(:airtable).first.destroy
    else
      RorVsWild.record_error(e, user_id: user.id)
    end
  end
end
