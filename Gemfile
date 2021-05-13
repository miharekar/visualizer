# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.1"

gem "rails"
gem "pg"
gem "redis"
gem "puma"
gem "webpacker", "~> 5.0"
gem "bootsnap", ">= 1.4.2", require: false

gem "kramdown"
gem "kramdown-parser-gfm"

gem "turbo-rails"

gem "slim"
gem "devise", git: "https://github.com/ghiculescu/devise.git", branch: "error-code-422"
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

gem "tickly"
gem "ferrum"

gem "pry-rails"
gem "pry-byebug"

group :development, :test do
  gem "dotenv-rails"
end

group :development do
  gem "app_profiler"
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.2"
  gem "letter_opener"
  gem "annotate"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-performance", require: false
end
