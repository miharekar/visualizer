import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "loader"]

  async fetch(event) {
    if (event.type === "click") {
      event.preventDefault()
    }

    const url = this.urlTarget.value
    if (!url) return

    try {
      this.loaderTarget.classList.remove("hidden")

      this.element.querySelectorAll('input, select, textarea, button').forEach(el => {
        el.disabled = true
        el.classList.add("opacity-50", "cursor-wait")
      })

      const response = await fetch(this.urlTarget.dataset.scrapeUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ url })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || 'Failed to fetch coffee info')
      }

      this.populateFields(data)
    } catch (error) {
      const template = document.getElementById("scraper-error-template")
      const notificationHtml = template.innerHTML
      const updatedNotification = notificationHtml.replace(
        'Something went wrong',
        error.message
      )

      const notificationsContainer = document.getElementById("notifications-container")
      notificationsContainer.insertAdjacentHTML("beforeend", updatedNotification)
    } finally {
      this.loaderTarget.classList.add("hidden")

      this.element.querySelectorAll('input, select, textarea, button').forEach(el => {
        el.disabled = false
        el.classList.remove("opacity-50", "cursor-wait")
      })
    }
  }

  populateFields(data) {
    const fields = [
      'name', 'roast_level', 'country', 'region', 'farm', 'farmer', 'variety',
      'elevation', 'processing', 'harvest_time', 'quality_score', 'tasting_notes'
    ]

    fields.forEach(field => {
      const input = document.querySelector(`#coffee_bag_${field}`)
      if (input && data[field]) {
        input.value = data[field]
      }
    })
  }
}