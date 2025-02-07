require "net/http"
require "json"
require "uri"

class LemonSqueezy
  def create_checkout(data)
    Client.new("/checkouts", method: :post, data:).make_request
  end

  def get_customer(id)
    Client.new("/customers/#{id}").make_request
  end

  def get_customers(params: {})
    Client.new("/customers", params:).make_request
  end

  def get_subscription(id)
    Client.new("/subscriptions/#{id}").make_request
  end

  def get_subscriptions(params: {})
    Client.new("/subscriptions", params:).make_request
  end

  def all_subscriptions
    Client.new("/subscriptions").paginate
  end

  def all_customers
    Client.new("/customers").paginate
  end
end
