ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

require "rails/test_help"
require "webmock/minitest"

ActiveModel::SecurePassword.min_cost = true

module ActiveSupport
  class TestCase
    include ActiveJob::TestHelper
    include FactoryBot::Syntax::Methods

    parallelize(workers: :number_of_processors)

    setup { WebMock.disable_net_connect! }

    teardown { WebMock.reset! }
  end
end
