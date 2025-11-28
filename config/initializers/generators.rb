Rails.application.config.generators do
  it.orm :active_record, primary_key_type: :uuid
end
