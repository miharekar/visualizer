# frozen_string_literal: true

class AirtableController < ApplicationController
  skip_before_action :verify_authenticity_token

  def notification
    Rails.logger.debug "Airtable notification received"
    Rails.logger.debug params
    head :ok
  end
end
