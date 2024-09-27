class OmniauthCallbacksController < ApplicationController
  def airtable
    oauth = OauthWrapper.new(request.env["omniauth.auth"])
    identity = Identity.find_by(oauth.identifiers)
    if identity
      identity.update!({user_id: Current.user.id}.merge(oauth.identifiers_with_blob_and_token))
    else
      Current.user.identities.create!(oauth.identifiers_with_blob_and_token)
    end
    AirtableUploadAllJob.perform_later(Current.user)

    redirect_to shots_path, notice: "Successfully connected to Airtable"
  end
end
