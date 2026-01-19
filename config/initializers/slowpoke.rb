Rails.application.configure do
  config.slowpoke.timeout = 25
end

ActiveSupport::Notifications.subscribe "timeout.slowpoke" do |_name, _start, _finish, _id, payload|
  request = Rack::Request.new(payload[:env])
  error = payload[:error] || Appsignal::SimpleMessage.new("Request timed out")

  Appsignal.report_error(error) do |transaction|
    transaction.set_action(request.request_method)
    transaction.set_tags(path: request.path, url: request.url, user_id: Current.user&.id, email: Current.user&.email, remote_ip: request.remote_ip, cloudflare_ip: request.headers["CF-Connecting-IP"], hetzner_lb: request.headers["X-Forwarded-For"])
  end
end
