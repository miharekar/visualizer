# frozen_string_literal: true

FactoryBot.define do
  factory :shared_shot do
    shot
    code { "ZXCV" }

    trait :old do
      code { "QWER" }
      created_at { 2.hours.ago }
    end
  end
end
