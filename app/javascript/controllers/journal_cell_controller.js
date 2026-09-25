import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  dirty() {
    this.element.dataset.unsaved = ""
  }

  submit() {
    if (this.element.hasAttribute("data-saving")) return true
    if (!this.element.reportValidity()) return false
    this.element.dataset.saving = ""
    this.inputTarget.readOnly = true
    this.errorTarget.textContent = ""
    this.element.requestSubmit()
    return true
  }

  complete(event) {
    if (event.detail.fetchResponse?.contentType?.includes("turbo-stream")) return
    delete this.element.dataset.saving
    this.dirty()
    this.inputTarget.readOnly = false
    this.errorTarget.textContent = "Not saved. Press Enter to retry."
  }

  navigate(event) {
    if (event.key !== "Enter" || event.isComposing) return
    event.preventDefault()
    if (this.element.hasAttribute("data-unsaved") && !this.submit()) return
    const cell = this.element.closest("td")
    const row = event.shiftKey ? cell.parentElement.previousElementSibling : cell.parentElement.nextElementSibling
    const control = row?.querySelector(`[data-column="${CSS.escape(cell.dataset.column)}"] [data-journal-cell-control]`)
    control?.focus()
    control?.select?.()
  }
}
