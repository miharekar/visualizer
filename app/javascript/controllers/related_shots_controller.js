import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const uuidV4Regex = /shots\/([A-F\d]{8}-[A-F\d]{4}-4[A-F\d]{3}-[89AB][A-F\d]{3}-[A-F\d]{12}$)/i

export default class extends Controller {
  static values = { shotId: String }

  goTo(event) {
    const shotId = event.currentTarget.value
    Turbo.visit("/shots/" + shotId)
  }

  compare(event) {
    const compare = event.currentTarget.value
    Turbo.visit("/shots/" + this.shotIdValue + "/compare/" + compare)
  }

  urlCompare(event) {
    const input = event.currentTarget
    const url = input.value
    const uuidMatch = url.match(uuidV4Regex)

    if (uuidMatch) {
      input.value = ""
      input.placeholder = "With any shot via its URL"
      input.classList.remove("focus:placeholder-red-500", "focus:ring-red-500", "focus:border-red-500")
      Turbo.visit("/shots/" + this.shotIdValue + "/compare/" + uuidMatch.pop())
    } else {
      input.value = ""
      input.placeholder = "Please enter a valid shot URL"
      input.classList.add("focus:placeholder-red-500", "focus:ring-red-500", "focus:border-red-500")
    }
  }

  async copyFrom(event) {
    const shotId = event.currentTarget.value
    if (!shotId) return

    try {
      const response = await fetch(`/api/shots/${shotId}?essentials=true`)
      if (!response.ok) throw new Error("Failed to fetch shot data")
      const data = await response.json()
      this.fillFormFields(data)
    } catch (error) {
      console.error("Error copying shot data:", error)
      alert("Error copying shot data. Something went wrong. See console for details.")
    }
  }

  fillFormFields(data) {
    const fields = ["barista", "grinder_model", "grinder_setting", "bean_brand", "bean_type", "roast_date", "roast_level", "espresso_notes", "bean_notes"]
    fields.forEach(field => this.setFieldValue(`shot[${field}]`, data[field]))

    if (data.metadata) {
      Object.entries(data.metadata).forEach(([key, value]) => {
        this.setFieldValue(`shot[metadata][${key}]`, value)
      })
    }

    if (data.tags) {
      document.getElementById('tag_list').value = data.tags.join(",")
      this.application.getControllerForElementAndIdentifier(document.getElementById('tags_controller'), "tags").renderTags()
    }
  }

  setFieldValue = (name, value) => {
    const field = document.querySelector(`[name="${name}"]`)
    if (!field) return

    const currentValue = field.value || ''
    const newValue = value || ''

    if (currentValue != newValue) {
      if (field.dataset.previousValue === undefined) {
        field.dataset.previousValue = currentValue
      }

      field.value = newValue
      field.classList.add("!bg-oxford-blue-50")

      const label = document.querySelector(`label[for="${field.id}"]`)

      if (label && !label.querySelector('[data-action*="related-shots#rollback"]')) {
        const originalText = label.innerHTML
        label.innerHTML = `<div class="flex justify-between items-center"><span>${originalText}</span><span class="cursor-pointer font-light standard-link ml-2" data-action="click->related-shots#rollback" title="${currentValue}">Revert</span></div>`
      }
    }
  }

  rollback(event) {
    const label = event.target.closest("label")
    const el = document.getElementById(label.getAttribute("for"))

    if (el && el.dataset.previousValue !== undefined) {
      el.value = el.dataset.previousValue
      el.classList.remove("!bg-oxford-blue-50")
      delete el.dataset.previousValue
      label.innerHTML = label.querySelector('div > span').innerHTML
    }
  }
}
