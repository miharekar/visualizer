# frozen_string_literal: true

class RefreshTokenJob < ApplicationJob
  queue_as :default

  def perform(identity)
    identity.refresh_token!

    AirtableShotUploadAllJob.set(wait: 2.minutes).perform_later(identity.user) if identity.airtable?
  end
end
