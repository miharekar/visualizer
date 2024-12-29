import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"
import { pageIsTurboPreview } from "helpers/turbo_helpers"

export default class extends Controller {
  static values = { vapidKey: String }
  static targets = ["bell"]

  async connect() {
    if (!pageIsTurboPreview()) {
      const enabled = await this.isEnabled()
      if (this.#allowed && !enabled) {
        this.bellTarget.classList.remove("hidden")
      }
    }
  }

  async attemptToSubscribe() {
    if (this.#allowed) {
      const registration = await this.#serviceWorkerRegistration || await this.#registerServiceWorker()
      switch (Notification.permission) {
        case "denied": { break }
        case "granted": { this.#subscribe(registration); break }
        case "default": { this.#requestPermissionAndSubscribe(registration) }
      }
    }
  }

  async isEnabled() {
    if (this.#allowed) {
      const registration = await this.#serviceWorkerRegistration
      const existingSubscription = await registration?.pushManager?.getSubscription()
      return Notification.permission == "granted" && registration && existingSubscription
    } else {
      return false
    }
  }

  get #allowed() {
    return navigator.serviceWorker && window.Notification
  }

  get #serviceWorkerRegistration() {
    return navigator.serviceWorker.getRegistration()
  }

  #registerServiceWorker() {
    return navigator.serviceWorker.register("/service-worker.js")
  }

  async #subscribe(registration) {
    registration.pushManager
      .subscribe({ userVisibleOnly: true, applicationServerKey: this.#vapidPublicKey })
      .then(subscription => {

        this.#syncPushSubscription(subscription)
        this.dispatch("ready")
      })
  }

  async #syncPushSubscription(subscription) {
    const response = await post("/push_subscriptions", {
      body: this.#extractJsonPayloadAsString(subscription),
      responseKind: "turbo-stream"
    })
    if (!response.ok) subscription.unsubscribe()
  }

  async #requestPermissionAndSubscribe(registration) {
    const permission = await Notification.requestPermission()
    if (permission === "granted") this.#subscribe(registration)
  }

  get #vapidPublicKey() {
    return Uint8Array.from(atob(this.vapidKeyValue), c => c.codePointAt(0))
  }

  #extractJsonPayloadAsString(subscription) {
    const { endpoint, keys: { p256dh, auth } } = subscription.toJSON()
    return JSON.stringify({ push_subscription: { endpoint, p256dh_key: p256dh, auth_key: auth } })
  }
}
