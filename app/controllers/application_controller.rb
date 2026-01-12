class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  before_action :set_timezone
  before_action :set_skin

  private

  def set_timezone
    Current.set_timezone_from_cookie(cookies["browser.timezone"])
  end

  def set_skin
    @skin = Current.user&.skin&.downcase || "system"
    @skin = [@skin, cookies["browser.colorscheme"].presence].compact.join(" ") if @skin == "system"
  end
end
