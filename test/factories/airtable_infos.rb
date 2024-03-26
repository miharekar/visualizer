FactoryBot.define do
  factory :airtable_info do
    identity

    trait :with_table do
      base_id { "app1234567890" }
      table_id { "tbl1234567890" }
      webhook_id { "ach1234567890" }
      table_fields { ["ID", "URL", "Start time", "Image"] + Airtable::Shots::STANDARD_FIELDS.keys + ["Portafilter basket", "Bean variety"] }
    end
  end
end
