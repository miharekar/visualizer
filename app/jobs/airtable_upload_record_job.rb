class AirtableUploadRecordJob < AirtableJob
  def perform(record)
    record.class.airtable_class.new(record.user).upload(record)
  end
end
