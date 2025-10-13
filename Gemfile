source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.7"

gem "active_link_to"
gem "appsignal"
gem "aws-sdk-s3", require: false
gem "bcrypt"
gem "bootsnap", require: false
gem "csv"
gem "doorkeeper"
gem "image_processing"
gem "importmap-rails"
gem "kramdown"
gem "kramdown-parser-gfm"
gem "memo_wise"
gem "mission_control-jobs"
gem "omniauth-airtable"
gem "omniauth-rails_csrf_protection"
gem "pg"
gem "pghero"
gem "pg_lock"
gem "postmark-rails"
gem "propshaft"
gem "inline_svg" # rubocop:disable Bundler/OrderedGems
gem "puma"
gem "pundit"
gem "rack-cors"
gem "rails", "~> 8.1.0.beta1"
gem "responders"
gem "solid_cable"
gem "solid_cache"
gem "solid_queue"
gem "sqlite3"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "thruster"
gem "tickly", github: "miharekar/tickly"
gem "turbo-rails"
gem "webauthn"
gem "web-push"

group :development, :test do
  gem "debug", require: "debug/prelude"
  gem "vernier"
end

group :development do
  gem "actual_db_schema"
  gem "annotaterb"
  gem "benchmark-ips"
  gem "brakeman", require: false
  gem "bundler-audit"
  gem "herb"
  gem "hotwire-spark"
  gem "kamal"
  gem "letter_opener"
  gem "reactionview"
  gem "rubocop-rails-omakase", require: false
  gem "ruby-lsp"
  gem "web-console"
end

group :test do
  gem "factory_bot_rails"
  gem "retest"
  gem "webmock"
end
