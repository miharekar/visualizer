# frozen_string_literal: true

class AirtableShotDeleteJob < ApplicationJob
  queue_as :default
  retry_on Airtable::TokenError, wait: :exponentially_longer, attempts: 5

  def perform(user, airtable_id)
    Airtable::Shots.new(user).delete(airtable_id)
  end
end
