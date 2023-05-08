# frozen_string_literal: true

class AirtableController < ApplicationController
  skip_before_action :verify_authenticity_token

  def notification
    airtable_info = AirtableInfo.find_by(webhook_id: params["webhook"]["id"])
    if airtable_info
      AirtableWebhookJob.perform_later(airtable_info)
    else
      RorVsWild.send_message("Airtable webhook received for unknown webhook id: #{params["webhook"]["id"]}", params:)
    end
    head :ok
  end
end
