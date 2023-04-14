# frozen_string_literal: true

class AirtableShotDeleteJob < ApplicationJob
  queue_as :default

  def perform(user, airtable_id)
    Airtable::ShotSync.new(user).delete(airtable_id)
  end
end
