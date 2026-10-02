ReActionView.configure do
  it.intercept_erb = true
  it.debug_mode = Rails.env.development?
  # Slots rewrite String frame IDs into dom_id calls, causing to_key errors. Re-enable after https://github.com/marcoroth/herb/issues/2715 is fixed.
  it.slots = false
  # Herb 0.11.0 instrumentation drops newlines after elsif, causing TypeError. Re-enable once https://github.com/marcoroth/herb/pull/2711 ships.
  it.instrumentation.enabled = false
end
