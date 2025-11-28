WebAuthn.configure do
  it.allowed_origins = [Rails.configuration.webauthn_origin]
  it.rp_name = "Visualizer"
end
