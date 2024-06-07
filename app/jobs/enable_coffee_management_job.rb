class EnableCoffeeManagementJob < ApplicationJob
  prepend MemoWise

  queue_as :low

  attr_reader :user

  def perform(user)
    @user = user
    upsert_attributes = user.shots.where(coffee_bag_id: nil).map do |shot|
      coffee_bag = coffee_bags["#{shot.bean_brand}_#{shot.bean_type}_#{shot.roast_date}"]
      next unless coffee_bag

      {id: shot.id, coffee_bag_id: coffee_bag.id, bean_brand: roasters[shot.bean_brand].name, bean_type: coffee_bag.name}
    end

    ActiveRecord::Base.transaction do
      Shot.upsert_all(upsert_attributes.compact, returning: false)
    end
  end

  private

  memo_wise def roasters
    user.shots.distinct.pluck(:bean_brand).reject(&:blank?).to_h do |name|
      [name, Roaster.for_user_by_name(user, name)]
    end
  end

  memo_wise def coffee_bags
    user.shots.distinct
      .pluck(:bean_brand, :bean_type, :roast_date, :roast_level)
      .reject { |bean_brand, bean_type, _, _| bean_brand.blank? || bean_type.blank? }
      .to_h do |bean_brand, bean_type, roast_date, roast_level|
        coffee_bag = CoffeeBag.for_roaster_by_name_and_date(roasters[bean_brand], bean_type, roast_date, roast_level:)

        ["#{bean_brand}_#{bean_type}_#{roast_date}", coffee_bag]
      end
  end
end
