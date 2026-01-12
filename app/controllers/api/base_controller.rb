module Api
  class Api::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
    rate_limit to: 50, within: 1.minute, name: "api-ip-1-minute", by: -> { request.headers["CF-Connecting-IP"].presence || request.remote_ip }
    rate_limit to: 200, within: 10.minutes, name: "api-ip-10-minutes", by: -> { request.headers["CF-Connecting-IP"].presence || request.remote_ip }

    include Authentication
    include Authorization
    include Paginatable

    prepend_before_action :add_request_tags
    skip_before_action :verify_authenticity_token

    rate_limit to: 200, within: 10.minutes, name: "api-user-10-minutes", if: -> { Current.user.present? }, by: -> { Current.user.id }
    rescue_from ActionController::TooManyRequests, with: :render_rate_limit

    private

    def add_request_tags
      Appsignal.add_tags(remote_ip: request.remote_ip, cloudflare_ip: request.headers["CF-Connecting-IP"])
    end

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

    def render_rate_limit
      Rails.logger.warn("Rate limit exceeded cf_ip=#{request.headers['CF-Connecting-IP']}")
      render json: {error: "Too many requests. Please try again later."}, status: :too_many_requests
    end
  end
end
