FactoryBot.define do
  factory :user do
    sequence(:email) { "person#{it}@example.com" }
    password { "password" }
    hide_shot_times { false }
    admin { false }
    beta { false }
    supporter { false }
    developer { false }
    coffee_management_enabled { false }

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

    trait :with_coffee_management do
      premium
      coffee_management_enabled { true }
    end

    trait :with_shot_metadata do
      metadata_fields { ["Portafilter basket", "Bean variety"] }
    end

    trait :with_coffee_bag_metadata do
      coffee_bag_metadata_fields { ["Bean density", "Bean color"] }
    end

    trait :with_airtable do
      premium
      with_shot_metadata
      with_coffee_bag_metadata
      identities { [association(:identity, :airtable)] }
    end
  end
end
