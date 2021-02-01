# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_timezone

  private

  def after_sign_in_path_for(_resource_or_scope)
    shots_path
  end

  def set_timezone
    zone = current_user&.timezone.presence || cookies["browser.timezone"] || "UTC"
    @timezone = ActiveSupport::TimeZone.new(zone)
  end
end
