# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.2"

gem "active_link_to"
gem "aws-sdk-s3", require: false
gem "bootsnap", require: false
gem "cloudinary"
gem "dalli"
gem "debug"
gem "devise", github: "heartcombo/devise"
gem "doorkeeper"
gem "image_processing"
gem "importmap-rails"
gem "kramdown"
gem "kramdown-parser-gfm"
gem "memoist"
gem "mini_magick"
gem "newrelic-infinite_tracing"
gem "newrelic_rpm"
gem "pagy"
gem "pg"
gem "pghero"
gem "pg_query"
gem "propshaft"
gem "puma"
gem "rack-attack"
gem "rails"
gem "redis"
gem "responders", github: "heartcombo/responders"
gem "sentry-rails"
gem "sentry-ruby"
gem "sentry-sidekiq"
gem "sidekiq"
gem "sidekiq-scheduler", github: "sidekiq-scheduler/sidekiq-scheduler"
gem "slim"
gem "stimulus-rails"
gem "stripe"
gem "tailwindcss-rails"
gem "tickly", github: "miharekar/tickly"
gem "turbo-rails"

gem "rack-mini-profiler"
gem "stackprof"

group :development, :test do
  gem "dotenv-rails"
end

group :development do
  gem "annotate"
  gem "benchmark-ips"
  gem "brakeman"
  gem "foreman", require: false
  gem "guard"
  gem "guard-minitest"
  gem "letter_opener"
  gem "listen"
  gem "standard", require: false
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "web-console"
end
