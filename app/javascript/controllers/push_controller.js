import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Check if the browser supports notifications
    if ("Notification" in window) {
      // Request permission from the user to send notifications
      Notification.requestPermission().then((permission) => {
        if (permission === "granted") {
          // If permission is granted, register the service worker
          this.registerServiceWorker()
          console.log("Service worker registered")
        } else if (permission === "denied") {
          console.warn("User rejected to allow notifications.")
        } else {
          console.warn("User still didn't give an answer about notifications.")
        }
      })
    } else {
      console.warn("Push notifications not supported.")
    }
    console.log("Push controller connected")
  }

  registerServiceWorker() {
    // Check if the browser supports service workers
    if ("serviceWorker" in navigator) {
      // Register the service worker script (service_worker.js)
      navigator.serviceWorker
        .register('service-worker.js')
        .then((serviceWorkerRegistration) => {
          // Check if a subscription to push notifications already exists
          serviceWorkerRegistration.pushManager
            .getSubscription()
            .then((existingSubscription) => {
              if (!existingSubscription) {
                // Convert the base64 VAPID key to Uint8Array
                const vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]').content
                const convertedVapidKey = this.urlBase64ToUint8Array(vapidPublicKey)

                // If no subscription exists, subscribe to push notifications
                serviceWorkerRegistration.pushManager
                  .subscribe({
                    userVisibleOnly: true,
                    applicationServerKey: convertedVapidKey  // Use the converted key
                  })
                  .then((subscription) => {
                    // Save the subscription on the server
                    this.saveSubscription(subscription)
                  })
              }
            })
        })
        .catch((error) => {
          console.error("Error during registration Service Worker:", error)
        })
    }
  }

  // Add this helper method to convert the VAPID key
  urlBase64ToUint8Array(base64String) {
    const padding = '='.repeat((4 - base64String.length % 4) % 4)
    const base64 = (base64String + padding)
      .replace(/\-/g, '+')
      .replace(/_/g, '/')

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }

  saveSubscription(subscription) {
    // Extract necessary subscription data
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

    // Send the subscription data to the server
    fetch("/push_subscriptions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        push_subscription: {
          endpoint,
          p256dh_key: p256dh,
          auth_key: auth
        }
      })
    }).catch(error => console.error("Failed to save subscription:", error))
  }
}
