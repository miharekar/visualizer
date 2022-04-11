# frozen_string_literal: true

module Api
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token

    private

    def verify_basic_user
      head :unauthorized unless current_user
    end

    def verify_doorkeeper_access
      doorkeeper_authorize!
    end

    def verify_write_access
      doorkeeper_token ? doorkeeper_authorize!(:write) : verify_basic_user
    end

    def current_user
      @current_user ||= doorkeeper_token ? user_from_doorkeeper : user_from_basic
    end

    def user_from_doorkeeper
      return unless valid_doorkeeper_token?

      User.find(doorkeeper_token.resource_owner_id)
    end

    def user_from_basic
      authenticate_with_http_basic do |email, password|
        user = User.find_by(email:)
        user if user&.valid_password?(password)
      end
    rescue ActiveRecord::StatementInvalid => e
      Rollbar.error(e, auth: request.authorization)
      raise e
    end
  end
end
