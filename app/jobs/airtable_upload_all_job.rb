class AirtableUploadAllJob < AirtableJob
  def perform(user, shot_ids = nil, force: false)
    identity = user.identities.find_by(provider: "airtable")
    return unless identity

    if identity.valid_token?
      if user.coffee_management_enabled?
        Airtable::Roasters.new(user).upload_multiple(user.roasters.where(airtable_id: nil))
        coffee_bags = force ? user.coffee_bags.where.not(notes: [nil, ""]) : user.coffee_bags.where(airtable_id: nil)
        Airtable::CoffeeBags.new(user).upload_multiple(coffee_bags.includes(:roaster))
      end

      shots = if shot_ids
        user.shots.where(id: shot_ids)
      elsif force
        user.shots.where.not(bean_notes: [nil, ""]).or(user.shots.where.not(espresso_notes: [nil, ""])).or(user.shots.where.not(private_notes: [nil, ""]))
      else
        user.shots.where(airtable_id: nil)
      end
      Airtable::Shots.new(user).upload_multiple(shots.includes(:coffee_bag))
    else
      identity.refresh_token!
      self.class.perform_later(user, shot_ids, force:)
    end
  end
end
