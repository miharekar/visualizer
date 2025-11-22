if Rails.env.development?
  ReActionView.configure do |config|
    config.intercept_erb = false
    config.debug_mode = true
  end
end
