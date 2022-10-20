# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :profiling
  before_action :set_timezone

  private

  def profiling
    Rack::MiniProfiler.authorize_request if current_user&.admin?
  end

  def signed_in_root_path(_resource_or_scope)
    shots_path
  end

  def set_timezone
    zone = current_user&.timezone.presence || cookies["browser.timezone"] || "UTC"
    @timezone = ActiveSupport::TimeZone.new(zone)
  end

  def check_admin!
    authenticate_user!
    redirect_to shots_path unless current_user.admin?
  end
end
