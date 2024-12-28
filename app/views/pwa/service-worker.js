self.addEventListener("push", async (event) => {
  const data = await event.data.json()
  event.waitUntil(
    self.registration.showNotification(data.title, {
      body: data.body,
      icon: data.icon,
      data: data.data,
      actions: [
        {
          action: "edit_shot",
          title: "Edit Shot",
        }
      ],
    })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()

  const baseUrl = event.notification.data?.url
  let targetUrl = "/"
  if (baseUrl) {
    targetUrl = event.action === "edit_shot" ? `${baseUrl}/edit` : baseUrl
  }

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      for (let client of windowClients) {
        if (client.url === targetUrl && 'focus' in client) {
          return client.focus()
        }
      }
      return clients.openWindow(targetUrl)
    })
  )
})
