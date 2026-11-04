require "test_helper"

class HealthControllerTest < ActionDispatch::IntegrationTest
  test "show returns ok when database is reachable" do
    get db_health_check_url

    assert_response :ok
  end

  test "show returns service unavailable when database is unreachable" do
    connection = ActiveRecord::Base.connection
    connection.define_singleton_method(:select_value) { |*| raise ActiveRecord::ConnectionNotEstablished }

    get db_health_check_url

    assert_response :service_unavailable
  ensure
    connection.singleton_class.remove_method(:select_value)
  end
end
