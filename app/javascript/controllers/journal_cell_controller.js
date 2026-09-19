import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  dirty() {
    this.element.dataset.unsaved = ""
  }

  submit() {
    if (this.submitting) return true
    if (!this.element.reportValidity()) return false
    this.submitting = true
    this.element.dataset.saving = ""
    this.inputTarget.readOnly = true
    this.errorTarget.textContent = ""
    this.element.requestSubmit()
    return true
  }

  complete(event) {
    if (event.detail.fetchResponse?.contentType?.includes("turbo-stream")) return
    this.submitting = false
    delete this.element.dataset.saving
    this.dirty()
    this.inputTarget.readOnly = false
    this.errorTarget.textContent = "Not saved. Press Enter to retry."
  }

  navigate(event) {
    if (event.key !== "Enter" || event.isComposing) return
    event.preventDefault()
    const cell = this.element.closest("td")
    const row = cell.closest("tr")
    const next = event.shiftKey ? row.previousElementSibling : row.nextElementSibling
    const control = next?.querySelector(`[data-column="${CSS.escape(cell.dataset.column)}"] [data-journal-cell-control]`)
    if (!this.submit() || !control) return
    control?.focus()
    control?.select?.()
  }
}
