class ApplicationController < ActionController::Base
  include Authentication

  before_action :set_timezone
  before_action :set_skin
  before_action :tag_request

  private

  def set_timezone
    zone = Current.user&.timezone.presence || cookies["browser.timezone"].presence || "UTC"
    @timezone = ActiveSupport::TimeZone.new(zone)
  end

  def set_skin
    @skin = Current.user&.skin&.downcase || "system"
    @skin = [@skin, cookies["browser.colorscheme"].presence].compact.join(" ") if @skin == "system"
  end

  def tag_request
    Appsignal.tag_request(email: Current.user&.email, user_id: Current.user&.id)
  end

  def check_admin!
    redirect_to shots_path unless Current.user.admin?
  end

  def check_premium!
    redirect_to premium_index_path, alert: "You must be a premium user to access this feature." unless Current.user.premium?
  end
end
