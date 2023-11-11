# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.2"

gem "active_link_to"
gem "aws-sdk-s3", require: false
gem "bootsnap", require: false
gem "cloudinary"
gem "devise"
gem "doorkeeper"
gem "image_processing"
gem "importmap-rails"
gem "kramdown"
gem "kramdown-parser-gfm"
gem "memoist"
gem "mini_magick"
gem "oj"
gem "omniauth-airtable", github: "miharekar/omniauth-airtable"
gem "omniauth-rails_csrf_protection"
gem "pagy"
gem "pg"
gem "propshaft"
gem "puma"
gem "rails"
gem "redis"
gem "responders"
gem "sidekiq"
gem "sidekiq-scheduler"
gem "slim"
gem "stimulus-rails"
gem "stripe"
gem "tailwindcss-rails"
gem "tickly", github: "miharekar/tickly"
gem "turbo-rails"

gem "appsignal"
gem "lograge"
gem "pghero"
gem "pg_query"
gem "rack-mini-profiler"
gem "stackprof"

group :development, :test do
  gem "debug"
end

group :development do
  gem "annotate"
  gem "benchmark-ips"
  gem "brakeman"
  gem "dockerfile-rails"
  gem "letter_opener"
  gem "rubocop", require: false
  gem "standard", require: false
  gem "standard-performance", require: false
  gem "standard-rails", require: false
  gem "web-console"
end

group :test do
  gem "guard"
  gem "guard-minitest"
  gem "webmock"
end
