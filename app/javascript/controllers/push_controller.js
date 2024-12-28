import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { vapidKey: String }

  connect() {
    if (!("Notification" in window)) return

    Notification.requestPermission().then((permission) => {
      if (permission !== "granted") return
      this.registerServiceWorker()
    })
  }

  registerServiceWorker() {
    if (!("serviceWorker" in navigator)) return

    navigator.serviceWorker
      .register('service-worker.js')
      .then((serviceWorkerRegistration) => {
        serviceWorkerRegistration.pushManager
          .getSubscription()
          .then((existingSubscription) => {
            if (existingSubscription) return

            serviceWorkerRegistration.pushManager
              .subscribe({
                userVisibleOnly: true,
                applicationServerKey: Uint8Array.from(atob(this.vapidKeyValue), c => c.codePointAt(0))
              })
              .then((subscription) => {
                this.saveSubscription(subscription)
              })
          })
      })
  }

  saveSubscription(subscription) {
    const endpoint = subscription.endpoint
    const p256dh = btoa(
      String.fromCharCode.apply(
        null,
        new Uint8Array(subscription.getKey("p256dh"))
      )
    )
    const auth = btoa(
      String.fromCharCode.apply(
        null,
        new Uint8Array(subscription.getKey("auth"))
      )
    )

    fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ push_subscription: { endpoint, p256dh_key: p256dh, auth_key: auth } })
    })
  }
}
