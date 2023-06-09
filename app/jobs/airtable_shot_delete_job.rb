# frozen_string_literal: true

class AirtableShotDeleteJob < ApplicationJob
  queue_as :default
  retry_on Airtable::TokenError, attempts: 2

  def perform(user, airtable_id)
    Airtable::Shots.new(user).delete(airtable_id)
  end
end
