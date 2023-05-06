# frozen_string_literal: true

class AirtableWebhookRefreshJob < ApplicationJob
  queue_as :default

  def perform(*args)
    AirtableInfo.find_each do |airtable_info|
      user = airtable_info.identity.user
      Airtable::Shots.new(user).webhook_refresh
    end
  end
end
