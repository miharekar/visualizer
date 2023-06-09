# frozen_string_literal: true

class AirtableJob < ApplicationJob
  queue_as :default
  retry_on Airtable::TokenError, attempts: 2
end
