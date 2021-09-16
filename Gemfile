# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.2"

gem "rails", github: "rails/rails", branch: "main"
gem "pg"
gem "redis"
gem "puma"
gem "bootsnap", require: false

gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

gem "kramdown"
gem "kramdown-parser-gfm"

gem "slim"
gem "devise", git: "https://github.com/miharekar/devise.git", branch: "rails7"
gem "responders", git: "https://github.com/heartcombo/responders.git"
gem "pagy"
gem "active_link_to"

gem "mini_magick"
gem "dalli"
gem "rollbar"
gem "cloudinary"
gem "aws-sdk-s3"
gem "sidekiq"
gem "memoist"

gem "tickly", git: "https://github.com/miharekar/tickly.git"
gem "ferrum"

gem "pry-rails"
gem "pry-byebug"

group :development, :test do
  gem "dotenv-rails"
end

group :development do
  gem "brakeman"
  gem "app_profiler"
  gem "web-console"
  gem "listen"
  gem "letter_opener"
  gem "annotate"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-performance", require: false
end
