class AirtableController < ApplicationController
  skip_before_action :verify_authenticity_token

  def notification
    airtable_info = AirtableInfo.find_by(webhook_id: params["webhook"]["id"])
    if airtable_info
      if airtable_info.identity.valid_token?
        AirtableWebhookJob.perform_later(airtable_info)
      else
        airtable_info.identity.refresh_token_later!
        AirtableWebhookJob.set(wait: 1.minute).perform_later(airtable_info)
      end
    else
      Appsignal.set_message("Airtable webhook received for unknown webhook id: #{params["webhook"]["id"]}")
    end
    head :ok
  end
end
