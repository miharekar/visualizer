class OmniauthCallbacksController < ApplicationController
  before_action :require_authentication
  before_action :check_premium!

  def airtable
    oauth = OauthWrapper.new(request.env["omniauth.auth"])
    identity = Identity.find_by(oauth.identifiers)
    if identity
      identity.update!({user_id: Current.user.id}.merge(oauth.identifiers_with_blob_and_token))
    else
      Current.user.identities.create!(oauth.identifiers_with_blob_and_token)
    end
    Airtable::Base.new(Current.user)
    AirtableUploadAllJob.perform_later(Current.user)

    redirect_to shots_path, notice: "Successfully connected to Airtable"
  rescue Airtable::BaseError
    redirect_to shots_path, alert: "Airtable not connected. Visualizer needs access to a base where you're a Creator. Please connect again and pick one."
  end
end
