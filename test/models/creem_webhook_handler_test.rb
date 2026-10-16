require "test_helper"

class CreemWebhookHandlerTest < ActiveSupport::TestCase
  test "handles subscription events" do
    user = create(:user)
    expires_at = 1.month.from_now.change(usec: 0)
    handler = handler_for("eventType" => "subscription.paid", "object" => {"customer" => {"id" => "cust_1", "email" => user.email}, "current_period_end_date" => expires_at.iso8601})

    handler.handle

    assert_equal expires_at, user.reload.premium_expires_at
    assert_equal "cust_1", user.creem_customer_id
  end

  test "ignores events that are not handled" do
    assert_nil handler_for("eventType" => "update_premium_expiry").handle
    assert_nil handler_for("eventType" => "sleep").handle
    assert_nil handler_for({}).handle
  end

  private

  def handler_for(payload)
    CreemWebhookHandler.allocate.tap { it.instance_variable_set(:@payload, payload) }
  end
end
