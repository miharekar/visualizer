class RefreshCoffeeBagFieldsOnShotsJob < ApplicationJob
  queue_as :default

  def perform(coffee_bag)
    coffee_bag.shots.each do
      it.refresh_coffee_bag_fields
      it.save!
    end
  end
end
