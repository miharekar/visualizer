FactoryBot.define do
  factory :identity do
    user

    uid { SecureRandom.hex(8) }
    provider { "provider" }
    token { "access_token" }
    refresh_token { "refresh_token" }
    expires_at { Time.utc(2030, 1, 1) }

    trait :airtable do
      provider { "airtable" }
      airtable_info { association(:airtable_info, :with_tables) }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end
  end
end
