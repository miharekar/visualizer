# frozen_string_literal: true

class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def airtable
    oauth = Oauth.new(request.env["omniauth.auth"])
    identity = Identity.find_by(oauth.identifiers)
    if identity
      identity.update!({user_id: current_user.id}.merge(oauth.identifiers_with_blob_and_token))
    else
      current_user.identities.create!(oauth.identifiers_with_blob_and_token)
    end

    redirect_to shots_path, notice: "Successfully connected to Airtable"
  end
end
