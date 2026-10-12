class OmniauthCallbacksController < ApplicationController
  skip_before_action :reject_unconfirmed_user, only: :homelab_oidc

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

  def homelab_oidc
    auth = request.env.fetch("omniauth.auth")
    issuer = auth.dig("extra", "raw_info", "iss").to_s
    configured_issuer = ENV.fetch("OIDC_ISSUER", "").chomp("/")
    subject = auth.dig("uid").to_s
    return oidc_failure("The identity provider did not return a valid issuer or subject.") if issuer.blank? || subject.blank? || issuer.chomp("/") != configured_issuer

    identity = Identity.find_by(provider: "homelab_oidc", uid: subject)
    if identity
      return oidc_failure("That OpenID Connect identity belongs to another account.") if Current.user && identity.user_id != Current.user.id

      start_new_session_for(identity.user)
      redirect_to after_authentication_url
    elsif Current.user
      Current.user.identities.create!(provider: "homelab_oidc", uid: subject, blob: auth)
      redirect_to shots_path, notice: "OpenID Connect account linked"
    else
      email = auth.dig("info", "email").to_s.strip.downcase
      return oidc_failure("The identity provider did not return an email address.") if email.blank?
      return oidc_failure("An account already uses this email address. Sign in locally once to link OpenID Connect.") if User.exists?(email:)

      user = User.transaction do
        user = provision_oidc_user(email)
        user.identities.create!(provider: "homelab_oidc", uid: subject, blob: auth)
        user
      end
      start_new_session_for(user)
      redirect_to after_authentication_url
    end
  rescue ActiveRecord::RecordNotUnique
    oidc_failure("That OpenID Connect identity is already linked to another account.")
  end

  def homelab_oidc_method_not_allowed
    response.set_header("Allow", "POST")
    render plain: "", status: :method_not_allowed, content_type: "text/plain"
  end

  private

  def oidc_failure(message)
    redirect_to new_session_url, alert: message
  end

  def provision_oidc_user(email)
    User.create!(email:, password: SecureRandom.base58(48), confirmed_at: Time.current)
  end
end
