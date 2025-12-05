import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canonicalId", "url", "loader"]

  async fetch(event) {
    if (event.type === "click") {
      event.preventDefault()
    }

    const url = this.urlTarget.value
    if (!url) return

    try {
      this.loaderTarget.classList.remove("hidden")

      this.element.querySelectorAll("input, select, textarea, button").forEach(el => {
        el.disabled = true
        el.classList.add("opacity-50", "cursor-wait")
      })

      const response = await fetch(this.urlTarget.dataset.scrapeUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ url })
      })

      const data = await response.json()

      if (!response.ok) {
        throw new Error(data.error || "Failed to fetch coffee info")
      }

      if (this.hasCanonicalIdTarget) {
        this.canonicalIdTarget.value = null
      }
      this.populateFields(data)
    } catch (error) {
      appsignal.sendError(error)
      const template = document.getElementById("scraper-error-template")
      const notificationHtml = template.innerHTML
      const updatedNotification = notificationHtml.replace("Something went wrong", error.message)

      const notificationsContainer = document.getElementById("notifications-container")
      notificationsContainer.insertAdjacentHTML("beforeend", updatedNotification)
    } finally {
      this.loaderTarget.classList.add("hidden")

      this.element.querySelectorAll("input, select, textarea, button").forEach(el => {
        el.disabled = false
        el.classList.remove("opacity-50", "cursor-wait")
      })
    }
  }

  populateFields(data) {
    const fields = ["name", "roast_level", "country", "region", "farm", "farmer", "variety", "elevation", "processing", "harvest_time", "quality_score", "tasting_notes"]

    fields.forEach(field => {
      const input = document.querySelector(`#coffee_bag_${field}`)
      if (input && data[field]) {
        this.updateField(input, data[field])
      }
    })
  }

  updateField(field, newValue) {
    const currentValue = field.value || ""

    if (field.dataset.previousValue === undefined) {
      field.dataset.previousValue = currentValue
    }

    const originalValue = field.dataset.previousValue
    if (currentValue != newValue) {
      field.value = newValue
      field.classList.add("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")

      const label = document.querySelector(`label[for="${field.id}"]`)
      if (label && !label.querySelector(`[data-action*="rollback"]`)) {
        const originalText = label.innerHTML
        label.innerHTML = `<div class="flex justify-between items-center"><span>${originalText}</span><span class="ml-2 font-light cursor-pointer standard-link" data-action="click->coffee-bag-scraper#rollback" title="${originalValue}">Revert</span></div>`
      }
    }
  }

  rollback(event) {
    const label = event.target.closest("label")
    const field = document.getElementById(label.getAttribute("for"))

    if (field && field.dataset.previousValue !== undefined) {
      field.value = field.dataset.previousValue
      field.classList.remove("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
      delete field.dataset.previousValue

      label.innerHTML = label.querySelector("div > span").innerHTML
    }
  }
}
