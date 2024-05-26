class RefreshCoffeeBagFieldsForShotJob < ApplicationJob
  queue_as :default

  def perform(shot)
    shot.refresh_coffee_bag_fields
    shot.save!
  end
end
