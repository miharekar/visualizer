module Api
  class BaseController < ApplicationController
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
  end
end
