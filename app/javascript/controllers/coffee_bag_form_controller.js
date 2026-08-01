import { Controller } from "@hotwired/stimulus"
import { plainTextToHtml } from "helpers/rich_text"

const FIELD_HIGHLIGHT_CLASSES = ["!bg-oxford-blue-50", "dark:!bg-oxford-blue-900"]

export default class extends Controller {
  applyPayload(event) {
    const { data = {}, clearCanonicalId = false } = event.detail || {}
    if (clearCanonicalId) {
      const canonicalId = this.field("canonical_coffee_bag_id")
      canonicalId.value = ""
      canonicalId.dispatchEvent(new Event("change"))
    }

    Object.entries(data).forEach(([fieldName, value]) => {
      if (!value) return

      const field = this.field(fieldName)
      if (!field) return

      this.updateField(field, value)
    })
  }

  revert(event) {
    const revert = event.currentTarget
    const label = revert.closest("label")
    const field = document.getElementById(label.getAttribute("for"))
    if (!field || field.dataset.previousValue === undefined) return

    field.value = field.dataset.previousValue
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.classList.remove(...FIELD_HIGHLIGHT_CLASSES)
    delete field.dataset.previousValue
    label.classList.remove("flex", "items-center", "justify-between")
    revert.remove()
  }

  updateField(field, newValue) {
    const value = field.tagName === "LEXXY-EDITOR" ? plainTextToHtml(newValue) : newValue
    if (field.value === value) return
    if (field.dataset.previousValue === undefined) field.dataset.previousValue = field.value || ""

    field.value = value
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.classList.add(...FIELD_HIGHLIGHT_CLASSES)
    this.addRollbackLink(field)
  }

  field(fieldName) {
    return this.element.querySelector(`#coffee_bag_${fieldName}`)
  }

  addRollbackLink(field) {
    const label = this.element.querySelector(`label[for="${field.id}"]`)
    if (!label) return
    if (label.querySelector(`[data-action*="coffee-bag-form#revert"]`)) return

    const revert = document.createElement("span")
    revert.className = "ml-2 font-light cursor-pointer standard-link"
    revert.dataset.action = "click->coffee-bag-form#revert"
    revert.title = field.dataset.previousValue
    revert.textContent = "Revert"

    label.classList.add("flex", "items-center", "justify-between")
    label.append(revert)
  }
}
