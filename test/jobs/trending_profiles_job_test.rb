require "test_helper"

class TrendingProfilesJobTest < ActiveJob::TestCase
  test "writes trending stats to cache" do
    recent_time = 3.hours.ago
    public_shot = create(:shot, public: true, profile_title: "Sweet Bloom", start_time: recent_time, espresso_enjoyment: 84)
    create(:shot_information, shot: public_shot, brewdata: {"parser" => "Parsers::Beanconqueror"})

    private_shot = create(:shot, public: false, profile_title: "Private Flow", start_time: recent_time)
    create(:shot_information, shot: private_shot, brewdata: {"parser" => "Parsers::Gaggiuino"})

    TrendingProfilesJob.perform_now

    trending = Rails.cache.read("community/trending/24h")
    assert_equal 1, trending[:public_count]
    assert_equal 2, trending[:total_count]
    assert_equal [{name: "Sweet Bloom", count: 1, avg_enjoyment: 84}], trending[:profiles]
    assert_equal [{name: "Beanconqueror", count: 1}], trending[:parsers]
  end
end
