class AirtableRoasterUploadAllJob < AirtableJob
  def perform(user, roasters: nil)
    roasters ||= user.roasters.where(airtable_id: nil)
    Airtable::Roasters.new(user).upload_multiple(roasters)
  end
end
