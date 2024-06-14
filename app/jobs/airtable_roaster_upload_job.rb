class AirtableRoasterUploadJob < AirtableJob
  def perform(roaster)
    Airtable::Roasters.new(roaster.user).upload(roaster)
  rescue Airtable::DataError => e
    Appsignal.set_error(e) do |transaction|
      transaction.set_tags(roaster_id: roaster.id, user_id: roaster.user_id)
    end
  end
end
