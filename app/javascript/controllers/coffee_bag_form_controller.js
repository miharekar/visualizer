import { Controller } from "@hotwired/stimulus"
import { plainTextToHtml } from "helpers/rich_text"

const FIELD_HIGHLIGHT_CLASSES = ["!bg-oxford-blue-50", "dark:!bg-oxford-blue-900"]

export default class extends Controller {
  connect() {
    this.handleApply = this.applyPayload.bind(this)
    this.element.addEventListener("coffee-bag:apply", this.handleApply)
  }

  disconnect() {
    this.element.removeEventListener("coffee-bag:apply", this.handleApply)
  }

  applyPayload(event) {
    const { data = {}, clearCanonicalId = false } = event.detail || {}
    if (clearCanonicalId) this.clearCanonicalId()

    Object.entries(data).forEach(([fieldName, value]) => {
      if (!value) return

      const field = this.field(fieldName)
      if (!field) return

      this.updateField(field, value)
    })
  }

  revert(event) {
    const label = event.target.closest("label")
    const field = label && document.getElementById(label.getAttribute("for"))
    if (!field || field.dataset.previousValue === undefined) return

    field.value = field.dataset.previousValue
    field.dispatchEvent(new Event("input", { bubbles: true }))
    field.classList.remove(...FIELD_HIGHLIGHT_CLASSES)
    delete field.dataset.previousValue
    const originalLabel = label.querySelector("[data-original-label]")
    label.replaceChildren(...originalLabel.childNodes)
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

    const wrapper = document.createElement("div")
    wrapper.className = "flex justify-between items-center"

    const originalLabel = document.createElement("span")
    originalLabel.dataset.originalLabel = ""
    originalLabel.append(...label.childNodes)

    const revert = document.createElement("span")
    revert.className = "ml-2 font-light cursor-pointer standard-link"
    revert.dataset.action = "click->coffee-bag-form#revert"
    revert.title = field.dataset.previousValue
    revert.textContent = "Revert"

    wrapper.append(originalLabel, revert)
    label.replaceChildren(wrapper)
  }

  clearCanonicalId() {
    const field = this.field("canonical_coffee_bag_id")
    if (field) field.value = ""
  }
}
