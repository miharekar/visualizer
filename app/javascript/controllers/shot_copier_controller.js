import { Controller } from "@hotwired/stimulus"

const uuidV4Regex = /shots\/([A-F\d]{8}-[A-F\d]{4}-4[A-F\d]{3}-[89AB][A-F\d]{3}-[A-F\d]{12})/i

export default class extends Controller {
  async from(event) {
    const shotId = event.currentTarget.value
    if (!shotId) return

    this.copyFrom(shotId)
  }

  async fromUrl(event) {
    const input = event.currentTarget
    const url = input.value
    const uuidMatch = url.match(uuidV4Regex)

    if (uuidMatch) {
      input.placeholder = "From any shot via its URL"
      input.classList.remove("focus:placeholder-red-500!", "focus:ring-red-500!", "focus:border-red-500!")
      this.copyFrom(uuidMatch.pop())
    } else {
      input.value = ""
      input.placeholder = "Please enter a valid shot URL"
      input.classList.add("focus:placeholder-red-500!", "focus:ring-red-500!", "focus:border-red-500!")
    }
  }

  async copyFrom(shotId) {
    try {
      const response = await fetch(`/api/shots/${shotId}?essentials=true`)
      if (!response.ok) throw new Error("Failed to fetch shot data")
      const data = await response.json()
      this.fillFormFields(data)
    } catch (error) {
      appsignal.sendError(error)
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

    if (data.tags && document.getElementById("tags_controller")) {
      const tagsController = this.application.getControllerForElementAndIdentifier(document.getElementById("tags_controller"), "tags")
      tagsController.tagify.removeAllTags()
      tagsController.tagify.addTags(data.tags)
    }

    if (data.coffee_bag_id) {
      const hiddenInput = document.querySelector('input[name="shot[coffee_bag_id]"]')
      const comboboxElement = hiddenInput?.closest('[data-controller~="combobox"]')
      const comboboxController = comboboxElement ? this.application.getControllerForElementAndIdentifier(comboboxElement, "combobox") : null

      if (comboboxController) {
        comboboxController.selectById(data.coffee_bag_id)
      }
    }

    if (document.getElementById("shot_canonical_coffee_bag_search")) {
      document.getElementById("shot_canonical_coffee_bag_search").value = ""
      document.getElementById("shot_canonical_coffee_bag_id").value = ""
    }
  }

  updateField(field, newValue, isTags = false) {
    const currentValue = field.value || ""

    if (field.dataset.previousValue === undefined) {
      field.dataset.previousValue = currentValue
    }

    const originalValue = field.dataset.previousValue
    if (currentValue != newValue) {
      field.value = newValue

      if (isTags) {
        document.getElementById("tags_input").classList.add("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
      } else {
        field.classList.add("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
      }

      const label = isTags ? document.querySelector(`label[for="tags_input"]`) : document.querySelector(`label[for="${field.id}"]`)
      const actionName = isTags ? "rollbackTags" : "rollback"
      if (label && !label.querySelector(`[data-action*="${actionName}"]`)) {
        const originalText = label.innerHTML
        label.innerHTML = `<div class="flex justify-between items-center"><span>${originalText}</span><span class="ml-2 font-light cursor-pointer standard-link" data-action="click->shot-copier#${actionName}" title="${originalValue}">Revert</span></div>`
      }
    }
  }

  setFieldValue = (name, value) => {
    const field = document.querySelector(`[name="${name}"]`)
    if (!field) return

    this.updateField(field, value || "", false)
  }

  rollback(event) {
    const label = event.target.closest("label")
    const el = document.getElementById(label.getAttribute("for"))

    this.handleRollback(el, label)
  }

  rollbackTags(event) {
    const label = event.target.closest("label")
    document.getElementById("tags_input").classList.remove("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")

    this.handleRollback(document.getElementById("tag_list"), label, () => {
      this.application.getControllerForElementAndIdentifier(document.getElementById("tags_controller"), "tags").renderTags()
    })
  }

  handleRollback(field, label, renderCallback = null) {
    if (field && field.dataset.previousValue !== undefined) {
      field.value = field.dataset.previousValue
      field.classList.remove("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
      delete field.dataset.previousValue

      label.innerHTML = label.querySelector("div > span").innerHTML

      if (renderCallback) {
        renderCallback()
      }
    }
  }
}
