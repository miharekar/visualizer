class AirtableUploadAllJob < AirtableJob
  def perform(user, shot_ids = nil)
    Airtable::Base.prepare_for(user)

    if user.coffee_management_enabled?
      Airtable::Roasters.new(user).upload_multiple(user.roasters.where(airtable_id: nil))
      Airtable::CoffeeBags.new(user).upload_multiple(CoffeeBag.where(roaster: user.roasters, airtable_id: nil).includes(:roaster))
    end

    shots = shot_ids ? user.shots.where(id: shot_ids) : user.shots.where(airtable_id: nil)
    Airtable::Shots.new(user).upload_multiple(shots.includes(:coffee_bag))
  end
end
