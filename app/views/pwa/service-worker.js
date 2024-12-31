self.addEventListener("push", async (event) => {
  const data = await event.data.json()
  event.waitUntil(
    self.registration.showNotification(data.title, { body: data.body, data: data.data })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data?.path || "/", self.location.origin).href
  event.waitUntil(self.clients.openWindow(url).then(windowClient => windowClient?.focus()))
})
