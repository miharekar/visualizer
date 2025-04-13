import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "form"]
  static values = { siteKey: String }

  connect() {
    window.onloadTurnstileCallback = this.onloadTurnstileCallback.bind(this)
    const turnstile_script = document.createElement("script")
    turnstile_script.src = "https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onloadTurnstileCallback&render=explicit"
    turnstile_script.async = true
    turnstile_script.defer = true
    this.formTarget.prepend(turnstile_script)
  }

  disconnect() {
    if (this.widgetId) {
      turnstile.remove(this.widgetId)
    }
  }

  onloadTurnstileCallback() {
    this.widgetId = turnstile.render(this.containerTarget, {
      sitekey: this.siteKeyValue,
      appearance: "interaction-only"
    })
  }
}
