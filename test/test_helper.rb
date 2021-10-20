# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    miha = User.find(ActiveRecord::FixtureSet.identify(:miha, :uuid))
    Shot.from_file(miha, "test/fixtures/files/20210921T085910.shot")
  end
end
