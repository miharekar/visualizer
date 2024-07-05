class ApplicationController < ActionController::Base
  before_action :profiling
  before_action :set_timezone
  before_action :set_skin
  before_action :tag_request

  private

  def profiling
    Rack::MiniProfiler.authorize_request if current_user&.admin?
  end

  def signed_in_root_path(_resource_or_scope)
    shots_path
  end

  def set_timezone
    zone = current_user&.timezone.presence || cookies["browser.timezone"].presence || "UTC"
    @timezone = ActiveSupport::TimeZone.new(zone)
  end

  def set_skin
    @skin = current_user&.skin&.downcase || "system"
    @skin = [@skin, cookies["browser.colorscheme"].presence].compact.join(" ") if @skin == "system"
  end

  def tag_request
    Appsignal.tag_request(email: current_user&.email, user_id: current_user&.id)
  end

  def check_admin!
    authenticate_user!
    redirect_to shots_path unless current_user.admin?
  end

  def check_premium!
    authenticate_user!
    redirect_to premium_index_path, alert: "You must be a premium user to access this feature." unless current_user.premium?
  end
end
