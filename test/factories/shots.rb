FactoryBot.define do
  factory :shot do
    user
    sha { SecureRandom.hex(20) }
    start_time { Time.current }
    public { false }

    trait :with_airtable do
      skip_airtable_sync { true }
      sequence(:airtable_id, 1000) { "rec#{it}" }
    end

    trait :with_information do
      information factory: :shot_information
    end
  end
end
