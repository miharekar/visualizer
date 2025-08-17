class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  before_action :set_timezone
  before_action :set_skin
  before_action :tag_request

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def pundit_user
    Current.user
  end

  def set_timezone
    zone = Current.user&.timezone.presence || cookies["browser.timezone"].presence
    @timezone = ActiveSupport::TimeZone.new(zone) || ActiveSupport::TimeZone.new("UTC")
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

  def user_not_authorized
    redirect_back_or_to shots_path, alert: "You are not authorized to perform this action."
  end
end
