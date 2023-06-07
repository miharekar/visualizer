# frozen_string_literal: true

class AirtableRefreshTokenJob < ApplicationJob
  queue_as :default

  def perform(identity, force: false)
    identity.refresh_token!(force:)
  end
end
