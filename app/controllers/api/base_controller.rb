# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :verify_current_user

    private

    def current_user
      @current_user ||= authenticate_with_http_basic do |email, password|
        user = User.find_by(email: email)
        user if user&.valid_password?(password)
      end
    end

    def verify_current_user
      head :unauthorized unless current_user
    end
  end
end
