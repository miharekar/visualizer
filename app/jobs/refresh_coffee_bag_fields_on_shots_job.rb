class RefreshCoffeeBagFieldsOnShotsJob < ApplicationJob
  queue_as :default

  def perform(coffee_bag)
    coffee_bag.shots.each do |shot|
      shot.refresh_coffee_bag_fields
      shot.save!
    end
  end
end
