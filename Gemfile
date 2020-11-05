# frozen_string_literal: true

ruby "2.6.6"

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "sinatra"
gem "sinatra-contrib"
gem "pry"
gem "slim"

group :production do
  gem "puma"
end

group :development do
  gem "rubocop"
end
