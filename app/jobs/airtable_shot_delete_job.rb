# frozen_string_literal: true

class AirtableShotDeleteJob < AirtableJob
  def perform(user, airtable_id)
    Airtable::Shots.new(user).delete(airtable_id)
  end
end
