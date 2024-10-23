class AirtableWebhookRefreshAllJob < AirtableJob
  def perform
    AirtableInfo.find_each do |airtable_info|
      AirtableWebhookRefreshJob.perform_later(airtable_info)
    end
  end
end
