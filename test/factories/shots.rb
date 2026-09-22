FactoryBot.define do
  factory :shot do
    user
    sha { "manual:#{SecureRandom.uuid}" }
    start_time { Time.current }
    public { false }

    trait :with_airtable do
      skip_airtable_sync { true }
      sequence(:airtable_id, 1000) { "rec#{it}" }
    end

    trait :with_information do
      sha { SecureRandom.hex(20) }
      information factory: :shot_information
    end
  end
end
