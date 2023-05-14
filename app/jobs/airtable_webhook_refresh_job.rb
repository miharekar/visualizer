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
    if %w[NOT_FOUND INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND].include?(json["error"]["type"])
      airtable_info.destroy
    else
      RorVsWild.record_error(e, user_id: user.id)
    end
  end
end
