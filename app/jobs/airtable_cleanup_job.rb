class AirtableCleanupJob < AirtableJob
  def perform(user, airtable_ids)
    ApplicationRecord.descendants.each do |model|
      next unless model.include?(Airtablable)

      user
        .public_send(model.name.underscore.pluralize)
        .where(airtable_id: airtable_ids)
        .update_all(airtable_id: nil) # rubocop:disable Rails/SkipsModelValidations
    end

    AirtableUploadAllJob.perform_later(user)
  end
end
