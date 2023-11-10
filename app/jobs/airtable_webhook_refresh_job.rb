# frozen_string_literal: true

class AirtableWebhookRefreshJob < AirtableJob
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
    json = Oj.load(e.message)
    if %w[NOT_FOUND INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND CANNOT_REFRESH_DISABLED_WEBHOOK].include?(json["error"]["type"])
      airtable_info.destroy
    else
      Appsignal.send_error(e) do |transaction|
        transaction.set_tags(user_id: user.id)
      end
    end
  end
end
