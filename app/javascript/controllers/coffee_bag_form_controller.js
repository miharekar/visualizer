import { Controller } from "@hotwired/stimulus"

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
    field.classList.remove(...FIELD_HIGHLIGHT_CLASSES)
    delete field.dataset.previousValue
    label.innerHTML = label.querySelector("div > span").innerHTML
  }

  updateField(field, newValue) {
    if (field.value === newValue) return
    if (field.dataset.previousValue === undefined) field.dataset.previousValue = field.value || ""

    field.value = newValue
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

    const originalText = label.innerHTML
    label.innerHTML = `<div class="flex justify-between items-center"><span>${originalText}</span><span class="ml-2 font-light cursor-pointer standard-link" data-action="click->coffee-bag-form#revert" title="${field.dataset.previousValue}">Revert</span></div>`
  }

  clearCanonicalId() {
    const field = this.field("canonical_coffee_bag_id")
    if (field) field.value = ""
  }
}
