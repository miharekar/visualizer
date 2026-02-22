FactoryBot.define do
  factory :shot_information do
    shot
    data { {"espresso_weight" => [0, 1]} }
  end
end
