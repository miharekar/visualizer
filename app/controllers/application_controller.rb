# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :setup_profiler, :set_timezone

  private

  def setup_profiler
    Rack::MiniProfiler.authorize_request if current_user && current_user.email == "miha@mr.si"
  end

  def set_timezone
    return unless cookies.key?("browser.timezone")

    @timezone = ActiveSupport::TimeZone.new(cookies["browser.timezone"])
  end
end
