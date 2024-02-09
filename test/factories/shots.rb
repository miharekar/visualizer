# frozen_string_literal: true

FactoryBot.define do
  factory :shot do
    user
    sha { SecureRandom.hex(20) }
    start_time { Time.current }

    trait :with_airtable do
      skip_airtable_sync { true }
      sequence(:airtable_id, 1000) { "rec#{_1}" }
    end
  end
end
