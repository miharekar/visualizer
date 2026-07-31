class AirtableUploadAllJob < AirtableJob
  def perform(user, shot_ids = nil)
    identity = user.identities.find_by(provider: "airtable")
    return unless identity

    if identity.valid_token?
      if user.coffee_management_enabled?
        Airtable::Roasters.new(user).upload_multiple(user.roasters.where(airtable_id: nil))
        Airtable::CoffeeBags.new(user).upload_multiple(user.coffee_bags.where(airtable_id: nil).includes(:roaster, :rich_text_notes))
      end

      shots = shot_ids ? user.shots.where(id: shot_ids) : user.shots.where(airtable_id: nil)
      Airtable::Shots.new(user).upload_multiple(shots.with_notes.includes(:coffee_bag))
    else
      identity.refresh_token!
    end
  end
end
