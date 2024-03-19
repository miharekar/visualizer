# frozen_string_literal: true

class AirtableController < ApplicationController
  skip_before_action :verify_authenticity_token

  def notification
    airtable_info = AirtableInfo.find_by(webhook_id: params["webhook"]["id"])
    if airtable_info
      if airtable_info.identity.valid_token?
        AirtableWebhookJob.perform_later(airtable_info)
      else
        RefreshTokenJob.perform_later(airtable_info.identity)
        AirtableWebhookJob.set(wait: 1.minute).perform_later(airtable_info)
      end
    else
      Appsignal.send_message("Airtable webhook received for unknown webhook id: #{params["webhook"]["id"]}")
    end
    head :ok
  end
end
