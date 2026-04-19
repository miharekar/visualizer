class AirtableWebhookRefreshAllJob < AirtableJob
  def perform
    AirtableInfo.find_each do |airtable_info|
      airtable_info.webhook_refresh_later
    end
  end
end
