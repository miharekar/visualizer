if defined?(ActualDbSchema)
  ActualDbSchema.configure do
    it.enabled = Rails.env.development?
    it.auto_rollback_disabled = ENV["ACTUAL_DB_SCHEMA_AUTO_ROLLBACK_DISABLED"].present?
    it.ui_enabled = Rails.env.development? || ENV["ACTUAL_DB_SCHEMA_UI_ENABLED"].present?
    it.git_hooks_enabled = true
  end
end
