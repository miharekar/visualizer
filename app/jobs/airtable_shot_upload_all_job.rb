# frozen_string_literal: true

class AirtableShotUploadAllJob < ApplicationJob
  queue_as :default
  retry_on Airtable::TokenError, attempts: 2

  def perform(user, shots: nil)
    shots ||= user.shots.where(airtable_id: nil)
    Airtable::Shots.new(user).upload_multiple(shots)
  end
end
