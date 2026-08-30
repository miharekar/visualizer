class AirtableController < ApplicationController
  rate_limit to: 60, within: 1.minute, name: "airtable-notification"

  skip_before_action :verify_authenticity_token

  def notification
    webhook = params["webhook"]
    webhook_id = webhook["id"] if webhook.is_a?(ActionController::Parameters)
    return head :bad_request if webhook_id.blank?

    airtable_info = AirtableInfo.find_by(webhook_id:)
    if airtable_info
      if airtable_info.identity.valid_token?
        AirtableWebhookJob.perform_later(airtable_info)
      else
        airtable_info.identity.refresh_token_later!
        AirtableWebhookJob.set(wait: 1.minute).perform_later(airtable_info)
      end
    else
      Appsignal.set_message("Airtable webhook received for unknown webhook id: #{webhook_id}")
    end
    head :ok
  end
end
