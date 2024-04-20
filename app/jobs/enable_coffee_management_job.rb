class EnableCoffeeManagementJob < ApplicationJob
  prepend MemoWise

  queue_as :low

  attr_reader :user

  def perform(user)
    @user = user
    upsert_attributes = user.shots.where(coffee_bag_id: nil).map do |shot|
      coffee_bag_id = coffee_bags["#{shot.bean_brand}_#{shot.bean_type}_#{shot.roast_date}"]
      next unless coffee_bag_id

      {id: shot.id, coffee_bag_id:}
    end

    ActiveRecord::Base.transaction do
      Shot.upsert_all(upsert_attributes.compact, returning: false)
      user.update!(coffee_management_enabled: true)
    end
  end

  private

  memo_wise def roasters
    user.shots.distinct.pluck(:bean_brand)
      .reject(&:blank?)
      .to_h { |name| [name, Roaster.find_or_create_by(user:, name:)] }
  end

  memo_wise def coffee_bags
    user.shots.distinct
      .pluck(:bean_brand, :bean_type, :roast_date, :roast_level)
      .reject { |bean_brand, bean_type, _, _| bean_brand.blank? || bean_type.blank? }
      .to_h do |bean_brand, bean_type, string_roast_date, roast_level|
        roast_date = Date.parse(string_roast_date) rescue nil
        coffee_bag = roasters[bean_brand].coffee_bags.find_or_create_by(name: bean_type, roast_date:) do |bag|
          bag.roast_level = roast_level
        end
        ["#{bean_brand}_#{bean_type}_#{string_roast_date}", coffee_bag.id]
      end
  end
end
