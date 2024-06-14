class AirtableCoffeeBagUploadJob < AirtableJob
  def perform(coffee_bag)
    Airtable::CoffeeBags.new(coffee_bag.user).upload(coffee_bag)
  rescue Airtable::DataError => e
    Appsignal.set_error(e) do |transaction|
      transaction.set_tags(coffee_bag_id: coffee_bag.id, user_id: coffee_bag.user.id)
    end
  end
end
