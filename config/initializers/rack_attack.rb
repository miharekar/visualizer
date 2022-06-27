# frozen_string_literal: true

Rack::Attack.blocklist("fail2ban") do |req|
  # After 3 blocked requests in 10 minutes, block all requests from that IP for 1 day.
  Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 3, findtime: 10.minutes, bantime: 1.day) do
    CGI.unescape(req.query_string).include?("/etc/passwd") ||
      req.path.include?("/etc/passwd") ||
      req.path.include?("wp-admin") ||
      req.path.include?("wp-login")
  end
end

Rack::Attack.blocklist("allow2ban") do |req|
  # After 10 requests in 30 minutes, block all requests from that IP for 1 day.
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 10, findtime: 30.minutes, bantime: 1.day) do
    req.path == "/users/sign_in" && req.post?
  end
end
