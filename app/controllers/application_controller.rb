# frozen_string_literal: true

class ApplicationController < ActionController::Base
  before_action :set_timezone

  private

  def set_timezone
    return unless cookies.key?("browser.timezone")

    @timezone = ActiveSupport::TimeZone.new(cookies["browser.timezone"])
  end
end
