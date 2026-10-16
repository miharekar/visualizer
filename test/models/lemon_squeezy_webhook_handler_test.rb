require "test_helper"

class LemonSqueezyWebhookHandlerTest < ActiveSupport::TestCase
  test "ignores events that are not handled" do
    assert_nil handler_for("meta" => {"event_name" => "update_premium_expiry"}).handle
    assert_nil handler_for("meta" => {"event_name" => "sleep"}).handle
    assert_nil handler_for({}).handle
  end

  private

  def handler_for(payload)
    LemonSqueezyWebhookHandler.allocate.tap { it.instance_variable_set(:@payload, payload) }
  end
end
