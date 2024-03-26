class AirtableShotUploadAllJob < AirtableJob
  def perform(user, shots: nil)
    shots ||= user.shots.where(airtable_id: nil)
    Airtable::Shots.new(user).upload_multiple(shots)
  end
end
