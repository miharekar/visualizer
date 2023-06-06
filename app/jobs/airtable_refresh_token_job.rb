# frozen_string_literal: true

class AirtableRefreshTokenJob < ApplicationJob
  queue_as :default

  def perform(identity)
    identity.refresh_token!
  end
end
