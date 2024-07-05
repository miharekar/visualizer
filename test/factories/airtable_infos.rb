FactoryBot.define do
  factory :airtable_info do
    identity

    trait :with_tables do
      base_id { "app1234567890" }
      webhook_id { "ach1234567890" }
      tables {
        {
          "Shots"=> {
            "id"=>"tbl1234567890",
            "fields"=> [
              {"name"=>"ID", "type"=>"singleLineText"},
              {"name"=>"URL", "type"=>"url"},
              {"name"=>"Start time", "type"=>"dateTime", "options"=>{"timeZone"=>"client", "dateFormat"=>{"name"=>"local"}, "timeFormat"=>{"name"=>"24hour"}}},
              {"name"=>"Image", "type"=>"multipleAttachments"},
              {"name"=>"Espresso enjoyment", "type"=>"number", "options"=>{"precision"=>0}},
              {"name"=>"Profile title", "type"=>"singleLineText"},
              {"name"=>"Duration", "type"=>"duration", "options"=>{"durationFormat"=>"h:mm:ss.SS"}},
              {"name"=>"Barista", "type"=>"singleLineText"},
              {"name"=>"Bean weight", "type"=>"singleLineText"},
              {"name"=>"Drink weight", "type"=>"singleLineText"},
              {"name"=>"Grinder model", "type"=>"singleLineText"},
              {"name"=>"Grinder setting", "type"=>"singleLineText"},
              {"name"=>"Bean brand", "type"=>"singleLineText"},
              {"name"=>"Bean type", "type"=>"singleLineText"},
              {"name"=>"Roast date", "type"=>"singleLineText"},
              {"name"=>"Roast level", "type"=>"singleLineText"},
              {"name"=>"Drink tds", "type"=>"singleLineText"},
              {"name"=>"Drink ey", "type"=>"singleLineText"},
              {"name"=>"Bean notes", "type"=>"richText"},
              {"name"=>"Espresso notes", "type"=>"richText"},
              {"name"=>"Private notes", "type"=>"richText"},
              {"name"=>"Portafilter basket", "type"=>"singleLineText"},
              {"name"=>"Bean variety", "type"=>"singleLineText"}
            ]
          },
          "Roasters"=> {
            "id"=>"tbl1234567891",
            "fields"=> [
              {"name"=>"ID", "type"=>"singleLineText"},
              {"name"=>"URL", "type"=>"url"},
              {"name"=>"Image", "type"=>"multipleAttachments"},
              {"name"=>"Name", "type"=>"singleLineText"},
              {"name"=>"Website", "type"=>"url"}
            ]
          }
        }
      }
    end
  end
end
