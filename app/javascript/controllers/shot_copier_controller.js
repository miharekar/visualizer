import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async from(event) {
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

    if (data.tags && document.getElementById("tags_controller")) {
      const tagsController = this.application.getControllerForElementAndIdentifier(document.getElementById("tags_controller"), "tags")
      tagsController.tagify.removeAllTags()
      tagsController.tagify.addTags(data.tags)
    }

    if (data.coffee_bag_id && data.roaster_id) {
      const frame = document.getElementById("coffee_bag_fields")
      if (frame) {
        frame.src = `/shots/coffee_bag_form?coffee_bag=${data.coffee_bag_id}`
        frame.reload()
      }
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
        label.innerHTML = `<div class="flex items-center justify-between"><span>${originalText}</span><span class="ml-2 font-light cursor-pointer standard-link" data-action="click->shot-copier#${actionName}" title="${originalValue}">Revert</span></div>`
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
