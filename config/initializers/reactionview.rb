if Rails.env.development?
  ReActionView.configure do
    it.intercept_erb = false
    it.debug_mode = true
  end
end
