module Api
  class Api::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
    rate_limit to: 50, within: 1.minute, name: "api-ip-1-minute"
    rate_limit to: 200, within: 10.minutes, name: "api-ip-10-minutes"

    include ActiveStorage::SetCurrent
    include Authentication
    include Authorization
    include Paginatable

    prepend_before_action :add_request_tags
    skip_before_action :verify_authenticity_token

    rate_limit to: 200, within: 10.minutes, name: "api-user-10-minutes", if: -> { Current.user.present? }, by: -> { Current.user.id }
    rescue_from ActionController::ParameterMissing, with: :render_bad_parameters
    rescue_from ActionController::TooManyRequests, with: :render_rate_limit
    rescue_from ActiveSupport::MessageVerifier::InvalidSignature, with: :render_invalid_image

    private

    def add_request_tags
      Appsignal.add_tags(remote_ip: request.remote_ip, cloudflare_ip: request.headers["CF-Connecting-IP"], hetzner_lb: request.headers["X-Forwarded-For"])
    end

    def resume_session
      Current.session ||= session_from_doorkeeper || session_from_basic
    end

    def session_from_doorkeeper
      return unless valid_doorkeeper_token?

      user = User.find_by(id: doorkeeper_token.resource_owner_id)
      Session.new(user:) if user
    end

    def session_from_basic
      authenticate_with_http_basic do |email, password|
        user = User.authenticate_by(email: email.downcase, password:)
        next unless user

        Session.new(user:)
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

    def render_disabled_user
      render json: {error: "This account has been disabled. Contact miha@visualizer.coffee for more information."}, status: :forbidden
    end

    def verify_basic_user
      head :unauthorized unless Current.user
    end

    def json_request?
      true
    end

    def render_bad_parameters(error)
      render json: {error: error.message}, status: :bad_request
    end

    def render_invalid_image
      render json: {error: "Image must be a file uploaded with multipart/form-data."}, status: :unprocessable_content
    end

    def render_rate_limit
      Rails.logger.warn("Rate limit exceeded cf_ip=#{request.headers['CF-Connecting-IP']}")
      render json: {error: "Too many requests. Please try again later."}, status: :too_many_requests
    end
  end
end
