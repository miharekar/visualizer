FactoryBot.define do
  factory :user do
    sequence(:email) { "person#{_1}@example.com" }
    password { "password" }

    trait :admin do
      admin { true }
    end

    trait :public do
      name { "Premium User" }
      public { true }
    end

    trait :premium do
      premium_expires_at { 1.week.from_now }
    end

    trait :with_metadata do
      metadata_fields { ["Portafilter basket", "Bean variety"] }
    end

    trait :with_airtable do
      premium
      with_metadata
      identities { [association(:identity, :airtable)] }
    end
  end
end
