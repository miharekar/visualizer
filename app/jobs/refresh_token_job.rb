# frozen_string_literal: true

class RefreshTokenJob < ApplicationJob
  queue_as :default

  def perform(identity)
    identity.refresh_token!
  end
end
