FactoryBot.define do
  factory :airtable_info do
    identity

    trait :with_tables do
      base_id { "app1234567890" }
      webhook_id { "ach1234567890" }
      tables do
        {
          "Shots" => {
            "id" => "tbl1234567890",
            "fields" => [
              {"name" => "ID", "type" => "singleLineText"},
              {"name" => "URL", "type" => "url"},
              {"name" => "Start time", "type" => "dateTime", "options" => {"timeZone" => "client", "dateFormat" => {"name" => "local"}, "timeFormat" => {"name" => "24hour"}}},
              {"name" => "Image", "type" => "multipleAttachments"},
              {"name" => "Coffee Bag", "type" => "multipleRecordLinks", "options" => {"linkedTableId" => "tblCoffeeBags"}},
              {"name" => "Espresso enjoyment", "type" => "number", "options" => {"precision" => 0}},
              {"name" => "Profile title", "type" => "singleLineText"},
              {"name" => "Duration", "type" => "duration", "options" => {"durationFormat" => "h:mm:ss.SS"}},
              {"name" => "Barista", "type" => "singleLineText"},
              {"name" => "Bean weight", "type" => "singleLineText"},
              {"name" => "Drink weight", "type" => "singleLineText"},
              {"name" => "Grinder model", "type" => "singleLineText"},
              {"name" => "Grinder setting", "type" => "singleLineText"},
              {"name" => "Bean brand", "type" => "singleLineText"},
              {"name" => "Bean type", "type" => "singleLineText"},
              {"name" => "Roast date", "type" => "singleLineText"},
              {"name" => "Roast level", "type" => "singleLineText"},
              {"name" => "Drink tds", "type" => "singleLineText"},
              {"name" => "Drink ey", "type" => "singleLineText"},
              {"name" => "Bean notes", "type" => "richText"},
              {"name" => "Espresso notes", "type" => "richText"},
              {"name" => "Private notes", "type" => "richText"},
              {"name" => "Portafilter basket", "type" => "singleLineText"},
              {"name" => "Bean variety", "type" => "singleLineText"},
              {"name" => "Tags", "type" => "multipleSelects", "options" => {"choices" => []}}
            ]
          },
          "Coffee Bags" => {
            "id" => "tblCoffeeBags",
            "fields" => [
              {"name" => "ID", "type" => "singleLineText"},
              {"name" => "URL", "type" => "url"},
              {"name" => "Image", "type" => "multipleAttachments"},
              {"name" => "Name", "type" => "singleLineText"},
              {"name" => "Roaster", "type" => "multipleRecordLinks", "options" => {"linkedTableId" => "tblRoasters"}},
              {"name" => "Country", "type" => "singleLineText"},
              {"name" => "Elevation", "type" => "singleLineText"},
              {"name" => "Farm", "type" => "singleLineText"},
              {"name" => "Farmer", "type" => "singleLineText"},
              {"name" => "Harvest time", "type" => "singleLineText"},
              {"name" => "Processing", "type" => "singleLineText"},
              {"name" => "Quality score", "type" => "singleLineText"},
              {"name" => "Region", "type" => "singleLineText"},
              {"name" => "Roast date", "type" => "date", "options" => {"dateFormat" => {"name" => "local"}}},
              {"name" => "Frozen date", "type" => "date", "options" => {"dateFormat" => {"name" => "local"}}},
              {"name" => "Defrosted date", "type" => "date", "options" => {"dateFormat" => {"name" => "local"}}},
              {"name" => "Roast level", "type" => "singleLineText"},
              {"name" => "Variety", "type" => "singleLineText"},
              {"name" => "Tasting notes", "type" => "singleLineText"},
              {"name" => "Archived at", "type" => "dateTime", "options" => {"timeZone" => "utc", "dateFormat" => {"name" => "local"}, "timeFormat" => {"name" => "24hour"}}},
              {"name" => "Place of purchase", "type" => "singleLineText"},
              {"name" => "Notes", "type" => "richText"},
              {"name" => "Bean density", "type" => "singleLineText"},
              {"name" => "Bean color", "type" => "singleLineText"}
            ]
          },
          "Roasters" => {
            "id" => "tblRoasters",
            "fields" => [
              {"name" => "ID", "type" => "singleLineText"},
              {"name" => "URL", "type" => "url"},
              {"name" => "Image", "type" => "multipleAttachments"},
              {"name" => "Name", "type" => "singleLineText"},
              {"name" => "Website", "type" => "url"}
            ]
          }
        }
      end
    end
  end
end
