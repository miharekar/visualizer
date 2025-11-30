class PasskeysController < ApplicationController
  def options
    options = WebAuthn::Credential.options_for_create(
      user: {id: Current.user.webauthn_id, name: Current.user.email, display_name: Current.user.display_name},
      exclude: Current.user.webauthn_credentials.pluck(:external_id),
      authenticator_selection: {user_verification: "required"}
    )
    session[:webauthn_challenge] = options.challenge
    render json: options
  end

  def create
    credential = WebAuthn::Credential.from_create(params.to_unsafe_h)
    credential.verify(session.delete(:webauthn_challenge), user_verification: true)
    Current.session.user.webauthn_credentials.create!(external_id: credential.id, public_key: credential.public_key, nickname: params[:nickname].presence)

    head :created
  rescue WebAuthn::Error, ActiveRecord::RecordInvalid => e
    render json: {error: e.message}, status: :unprocessable_content
  end

  def destroy
    credential = Current.user.webauthn_credentials.find(params[:id])
    credential.destroy!

    respond_to do
      it.turbo_stream { render turbo_stream: turbo_stream.remove(credential) }
      it.html { redirect_to edit_profile_path }
    end
  end

  def sign_in
    opts = WebAuthn::Credential.options_for_get
    session[:webauthn_challenge] = opts.challenge
    render json: opts
  end

  def callback
    assertion = WebAuthn::Credential.from_get(params.to_unsafe_h)
    credential = WebauthnCredential.find_by!(external_id: assertion.id)
    assertion.verify(session.delete(:webauthn_challenge), public_key: credential.public_key, sign_count: credential.sign_count)
    credential.update!(sign_count: assertion.sign_count, last_used_at: Time.current)
    start_new_session_for(credential.user)
    render json: {redirect_to: after_authentication_url}
  rescue ActiveRecord::RecordNotFound, WebAuthn::Error
    head :unauthorized
  end
end
