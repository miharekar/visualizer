class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  before_action :set_timezone
  before_action :set_skin

  private

  def render_api_endpoint_error
    render json: {error: "This is not an API endpoint.", api_docs: "https://apidocs.visualizer.coffee"}, status: :not_acceptable
  end

  def set_timezone
    Current.set_timezone_from_cookie(cookies["browser.timezone"])
  end

  def set_skin
    @skin = Current.user&.skin&.downcase || "system"
    @skin = [@skin, cookies["browser.colorscheme"].presence].compact.join(" ") if @skin == "system"
  end
end
