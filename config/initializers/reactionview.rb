if Rails.env.development?
  ReActionView.configure do
    it.intercept_erb = true
    it.debug_mode = true
  end
end
