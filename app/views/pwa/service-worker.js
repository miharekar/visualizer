self.addEventListener("push", async (event) => {
  const data = await event.data.json()
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: data.icon,
      data: data.data
    })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const targetPath = event.notification.data?.path || "/"
  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      for (let client of windowClients) {
        if (client.path === targetPath && 'focus' in client) {
          return client.focus()
        }
      }
      return clients.openWindow(targetPath)
    })
  )
})