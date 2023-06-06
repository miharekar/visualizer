# frozen_string_literal: true

class AirtableShotDownloadJob < ApplicationJob
  queue_as :default
  retry_on Airtable::TokenError, wait: :exponentially_longer, attempts: 5

  def perform(user, minutes: 60)
    Airtable::Shots.new(user).download(minutes:)
  end
end
