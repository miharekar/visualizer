class AirtableDeleteRecordJob < AirtableJob
  def perform(klass, user, airtable_id)
    klass.new(user).delete(airtable_id)
  end
end
