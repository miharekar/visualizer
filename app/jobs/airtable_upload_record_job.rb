class AirtableUploadRecordJob < AirtableJob
  def perform(record)
    record.class.airtable_class.new(record.user).upload(record)
  rescue Airtable::DataError => e
    Appsignal.set_error(e) do |transaction|
      transaction.set_tags(record_class: record.class.name, record_id: record.id, user_id: record.user_id)
    end
  end
end
