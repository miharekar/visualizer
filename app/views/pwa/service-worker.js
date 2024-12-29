self.addEventListener("push", async (event) => {
  const data = await event.data.json()
  event.waitUntil(
    self.registration.showNotification(data.title, { body: data.body, data: data.data })
  )
})

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data?.path || "/", self.location.origin).href
  event.waitUntil(openURL(url))
})

async function openURL(url) {
  const clients = await self.clients.matchAll({ type: "window" })
  const focused = clients.find((client) => client.focused)

  if (focused) {
    try {
      const navigated = await focused.navigate(url)
      if (!navigated) {
        await self.clients.openWindow(url)
      }
    } catch (e) {
      await self.clients.openWindow(url)
    }
  } else {
    await self.clients.openWindow(url)
  }
}
