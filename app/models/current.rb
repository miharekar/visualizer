class Current < ActiveSupport::CurrentAttributes
  attribute :session, :timezone
  delegate :user, to: :session, allow_nil: true

  resets { Time.zone = nil }

  def set_timezone_from_cookie(cookie_zone)
    zone = user&.timezone.presence || cookie_zone.to_s.encode("UTF-8", invalid: :replace, undef: :replace, replace: "").strip.presence
    self.timezone = zone && ActiveSupport::TimeZone[zone] || ActiveSupport::TimeZone["UTC"]
    Time.zone = timezone
  end
end
