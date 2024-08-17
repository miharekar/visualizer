ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "minitest/unit"
require "webmock/minitest"

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
    include FactoryBot::Syntax::Methods

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    setup do
      ActionCable.server.pubsub.clear
      WebMock.disable_net_connect!
    end

    teardown do
      WebMock.reset!
    end
  end
end
