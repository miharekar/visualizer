module Api
  class CredentialsController < Api::BaseController
    before_action :verify_read_access

    def me
      render json: {
        id: Current.user.id,
        name: Current.user.display_name,
        public: Current.user.public?,
        avatar_url: Current.user.avatar.attached? ? url_for(Current.user.avatar) : Current.user.gravatar_url
      }
    end
  end
end
