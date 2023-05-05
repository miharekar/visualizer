# frozen_string_literal: true

class AirtableWebhookRefreshJob < ApplicationJob
  queue_as :default

  def perform(*args)
    AirtableInfo.find_each do |airtable_info|
      user = airtable_info.identity.user
      Airtable::ShotSync.new(user).table.webhook_refresh
    end
  end
end
