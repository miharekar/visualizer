# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_timezone

  private

  def set_timezone
    zone = cookies["browser.timezone"] || "UTC"
    @timezone = ActiveSupport::TimeZone.new(zone)
  end
end
