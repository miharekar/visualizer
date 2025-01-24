if defined?(ActualDbSchema)
  ActualDbSchema.configure do |config|
    config.enabled = Rails.env.development?
    config.auto_rollback_disabled = ENV["ACTUAL_DB_SCHEMA_AUTO_ROLLBACK_DISABLED"].present?
    config.ui_enabled = Rails.env.development? || ENV["ACTUAL_DB_SCHEMA_UI_ENABLED"].present?
    config.git_hooks_enabled = true
  end
end
