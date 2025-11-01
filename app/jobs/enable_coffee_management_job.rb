class EnableCoffeeManagementJob < ApplicationJob
  include DateParseable
  prepend MemoWise

  queue_as :low

  attr_reader :user

  def perform(user)
    @user = user
    upsert_attributes = user.shots.where(coffee_bag_id: nil).filter_map do |shot|
      coffee_bag = coffee_bags["#{shot.bean_brand}_#{shot.bean_type}_#{shot.roast_date}"]
      next unless coffee_bag

      {id: shot.id, sha: shot.sha, start_time: shot.start_time, coffee_bag_id: coffee_bag.id, bean_brand: roasters[shot.bean_brand].name, bean_type: coffee_bag.name}
    end

    ActiveRecord::Base.transaction do
      Shot.upsert_all(upsert_attributes, returning: false) # rubocop:disable Rails/SkipsModelValidations
    end
    return if user.identities.by_provider(:airtable).empty?

    AirtableUploadAllJob.perform_later(user, upsert_attributes.pluck(:id))
  end

  private

  memo_wise def roasters
    user.shots.distinct.pluck(:bean_brand).compact_blank.index_with do |name|
      Roaster.for_user_by_name(user, name, skip_airtable_sync: true)
    end
  end

  memo_wise def coffee_bags
    user.shots.distinct
      .pluck(:bean_brand, :bean_type, :roast_date, :roast_level)
      .reject { |bean_brand, bean_type, _, _| bean_brand.blank? || bean_type.blank? }
      .to_h do |bean_brand, bean_type, roast_date, roast_level|
        parsed_roast_date = parse_date(roast_date, user.date_format_string)
        coffee_bag = CoffeeBag.for_roaster_by_name_and_date(roasters[bean_brand], bean_type, parsed_roast_date, roast_level:, skip_airtable_sync: true)

        ["#{bean_brand}_#{bean_type}_#{roast_date}", coffee_bag]
      end
  end
end
