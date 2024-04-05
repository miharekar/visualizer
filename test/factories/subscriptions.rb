FactoryBot.define do
  factory :subscription do
    customer
    stripe_id { "sub_1234567890" }
    status { "active" }
    interval { "year" }
    started_at { "2022-04-03 20:42:10" }
  end
end
