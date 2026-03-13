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
    const fields = ["barista", "bean_weight", "drink_weight", "grinder_model", "grinder_setting", "bean_brand", "bean_type", "roast_date", "roast_level", "espresso_notes", "bean_notes", "private_notes", "fragrance", "aroma", "flavor", "aftertaste", "acidity", "bitterness", "sweetness", "mouthfeel"]
    fields.forEach(field => this.setFieldValue(`shot[${field}]`, data[field]))

    if (data.metadata) {
      Object.entries(data.metadata).forEach(([key, value]) => {
        this.setFieldValue(`shot[metadata][${key}]`, value)
      })
    }

    if (data.tags && document.getElementById("tags_controller")) {
      const tagsController = this.application.getControllerForElementAndIdentifier(document.getElementById("tags_controller"), "tags")
      const tagField = document.querySelector('#tags_controller [name="shot[tag_list]"]')
      const currentTags = tagsController.tagify.value.map(tag => tag.value)

      if (tagField && tagField.dataset.previousValue === undefined) {
        tagField.dataset.previousValue = JSON.stringify(currentTags)
      }

      tagsController.tagify.removeAllTags()
      tagsController.tagify.addTags(data.tags)

      if (tagField && JSON.stringify(currentTags) != JSON.stringify(data.tags)) {
        tagsController.inputTarget.classList.add("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
        this.showRevert(tagField, currentTags.join(", "), true)
      }
    }

    if (data.coffee_bag_id) {
      const hiddenInput = document.querySelector('input[name="shot[coffee_bag_id]"]')
      const comboboxElement = hiddenInput?.closest('[data-controller~="combobox"]')
      const comboboxController = comboboxElement ? this.application.getControllerForElementAndIdentifier(comboboxElement, "combobox") : null

      if (comboboxController) comboboxController.selectById(data.coffee_bag_id)
    }

    if (document.getElementById("shot_canonical_coffee_bag_search")) {
      document.getElementById("shot_canonical_coffee_bag_search").value = ""
      document.getElementById("shot_canonical_coffee_bag_id").value = ""
    }
  }

  updateField(field, newValue, isTags = false) {
    if (this.shouldPreserveExistingValue(field)) return

    const currentValue = field.value || ""

    if (field.dataset.previousValue === undefined) field.dataset.previousValue = currentValue

    const originalValue = field.dataset.previousValue
    if (currentValue != newValue) {
      field.value = newValue
      field.dispatchEvent(new Event("input", { bubbles: true }))

      if (isTags) {
        document.getElementById("tags_input").classList.add("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
      } else {
        field.classList.add("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
      }

      this.showRevert(field, originalValue, isTags)
    }
  }

  showRevert(field, originalValue, isTags = false) {
    const revert = this.revertButton(field.id, isTags)
    if (!revert) return

    revert.title = originalValue
    revert.classList.remove("hidden")
  }

  revertButton(fieldId, isTags = false) {
    const selector = isTags ? '[data-action="click->shot-copier#rollbackTags"]' : `[data-revert-for="${fieldId}"]`
    return document.querySelector(selector)
  }

  removeRevert(field, isTags = false) {
    const revert = this.revertButton(field.id, isTags)
    if (!revert) return

    revert.title = ""
    revert.classList.add("hidden")
  }

  setFieldValue = (name, value) => {
    const field = document.querySelector(`[name="${name}"]`)
    if (!field) return
    if (value === undefined) return

    this.updateField(field, value ?? "", false)
  }

  shouldPreserveExistingValue(field) {
    if (field.dataset.shotCopierPreserveExistingValue !== "true") return false

    const currentValue = (field.value ?? "").toString().trim()
    return !["", "0", "0.0"].includes(currentValue)
  }

  rollback(event) {
    event.preventDefault()
    const field = document.getElementById(event.currentTarget.dataset.revertFor)
    this.handleRollback(field)
  }

  rollbackTags(event) {
    event.preventDefault()

    const tagField = document.querySelector('#tags_controller [name="shot[tag_list]"]')
    if (!tagField || tagField.dataset.previousValue === undefined) return

    const tagsController = this.application.getControllerForElementAndIdentifier(document.getElementById("tags_controller"), "tags")
    tagsController.inputTarget.classList.remove("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
    const previousTags = JSON.parse(tagField.dataset.previousValue)

    tagsController.tagify.removeAllTags()
    tagsController.tagify.addTags(previousTags)

    delete tagField.dataset.previousValue
    this.removeRevert(tagField, true)
  }

  handleRollback(field, isTags = false, renderCallback = null) {
    if (!field || field.dataset.previousValue === undefined) return

    field.value = field.dataset.previousValue
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.classList.remove("!bg-oxford-blue-50", "dark:!bg-oxford-blue-900")
    delete field.dataset.previousValue
    this.removeRevert(field, isTags)

    if (renderCallback) renderCallback()
  }
}
