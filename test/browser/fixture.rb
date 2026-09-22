raise "development/test only" unless Rails.env.local?

email = ENV.fetch("JOURNAL_BROWSER_EMAIL")
raise "dedicated browser account required" unless email.match?(/\Ajournal-browser-[0-9a-f-]{36}@example\.invalid\z/)

ActiveJob::Base.queue_adapter = :test
case ARGV.fetch(0)
when "setup"
  raise "account already exists" if User.exists?(email:)

  User.transaction do
    user = User.create!(email:, password: ENV.fetch("JOURNAL_BROWSER_PASSWORD"), name: "Journal Browser Fixture", supporter: true, journal_enabled: true, coffee_management_enabled: true, timezone: "UTC")
    now = Time.current
    35.times { |i| user.shots.create!(sha: "manual:#{SecureRandom.uuid}", start_time: now - i.minutes, profile_title: "Browser Journal #{i}", espresso_enjoyment: 50, bean_weight: "18", drink_weight: "36", duration: 30) }
    roaster = user.roasters.create!(name: "Browser Roaster")
    roaster.coffee_bags.create!(name: "Browser Managed Coffee", roast_date: Date.current)
    user.shots.order(start_time: :desc).second.update!(tag_list: "browser-tag")
  end
when "cleanup"
  user = User.find_by(email:)
  if user
    raise "unexpected account" unless user.name == "Journal Browser Fixture"

    User.transaction do
      user.shots.destroy_all
      user.destroy!
    end
  end
else
  raise "expected setup or cleanup"
end
