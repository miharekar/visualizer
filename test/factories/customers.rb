FactoryBot.define do
  factory :customer do
    user
    stripe_id { "cus_1234567890" }
    amount { 1000 }
    payments { ["pi_1234567890"] }
    refunds { ["re_1234567890"] }
  end
end
