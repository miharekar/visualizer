class AirtableCoffeeBagUploadAllJob < AirtableJob
  def perform(user, coffee_bags: nil)
    coffee_bags ||= CoffeeBag.where(roaster: user.roasters, airtable_id: nil)
    Airtable::CoffeeBags.new(user).upload_multiple(coffee_bags.includes(:roaster))
  end
end
