# frozen_string_literal: true

class AirtableWebhookRefreshJob < ApplicationJob
  queue_as :default

  def perform(*args)
    AirtableInfo.find_each do |airtable_info|
      refresh_webhook(airtable_info)
    end
  end

  private

  def refresh_webhook(airtable_info)
    user = airtable_info.identity.user
    Airtable::Shots.new(user).webhook_refresh
  rescue Airtable::DataError => e
    json = JSON.parse(e.message)
    if json["error"]["type"] == "NOT_FOUND"
      airtable_info.destroy
    else
      RorVsWild.report_exception(e, user_id: user.id)
    end
  end
end
