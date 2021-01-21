# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.7.2"

gem "rails"
gem "pg"
gem "puma"
gem "sass-rails", ">= 6"
gem 'webpacker', '~> 5.0'
gem "bootsnap", ">= 1.4.2", require: false

gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"

gem "slim"
gem "devise"
gem "pagy"

gem "dalli"
gem "rollbar"
gem "cloudinary"
gem "delayed_job_active_record"
gem "memoist"

gem "tickly"
gem "selenium-webdriver"

gem "pry-rails"
gem "pry-byebug"

group :development, :test do

  gem "dotenv-rails"
end

group :development do
  gem "web-console", ">= 3.3.0"
  gem "listen", "~> 3.2"
  gem "letter_opener"
  gem "annotate"
  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-performance", require: false
end
