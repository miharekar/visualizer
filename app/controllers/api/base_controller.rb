module Api
  class Api::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
    rate_limit to: 50, within: 1.minute, name: "api-ip-1-minute", by: -> { request.headers["CF-Connecting-IP"].presence || request.remote_ip }
    rate_limit to: 200, within: 10.minutes, name: "api-ip-10-minutes", by: -> { request.headers["CF-Connecting-IP"].presence || request.remote_ip }

    include Authentication
    include Authorization
    include Paginatable

    skip_before_action :verify_authenticity_token

    private

    def resume_session
      Current.session ||= find_session_by_cookie || start_session_from_doorkeeper || start_session_from_basic
    end

    def start_session_from_doorkeeper
      return unless valid_doorkeeper_token?

      user = User.find_by(id: doorkeeper_token.resource_owner_id)
      return unless user

      start_new_session_for(user)
    end

    def start_session_from_basic
      authenticate_with_http_basic do |email, password|
        user = User.authenticate_by(email: email.downcase, password:)
        next unless user

        start_new_session_for(user)
      end
    end

    def verify_read_access
      doorkeeper_token ? doorkeeper_authorize! : verify_basic_user
    end

    def verify_upload_access
      doorkeeper_token ? doorkeeper_authorize!(:upload, :write) : verify_basic_user
    end

    def verify_write_access
      doorkeeper_token ? doorkeeper_authorize!(:write) : verify_basic_user
    end

    def verify_basic_user
      head :unauthorized unless Current.user
    end

    def user_not_authorized
      render json: {error: "You are not authorized to perform this action."}, status: :forbidden
    end
  end
end
