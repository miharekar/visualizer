# frozen_string_literal: true

module Api
  class CredentialsController < Api::BaseController
    before_action :verify_read_access

    def me
      json = {
        id: current_user.id,
        name: current_user.display_name,
        public: current_user.public?,
        avatar_url: current_user.avatar.attached? ? url_for(current_user.avatar) : current_user.gravatar_url
      }

      render json:
    end
  end
end
