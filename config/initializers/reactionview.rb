if Rails.env.development?
  ReActionView.configure do |config|
    config.intercept_erb = true
    config.debug_mode = false
  end
end
