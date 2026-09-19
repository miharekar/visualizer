import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  submit() {
    if (this.submitting || !this.element.reportValidity()) return
    this.submitting = true
    this.inputTarget.readOnly = true
    this.errorTarget.textContent = ""
    this.element.requestSubmit()
  }

  complete(event) {
    this.submitting = false
    this.inputTarget.readOnly = false
    if (!event.detail.success) this.errorTarget.textContent = "Not saved. Press Enter to retry."
  }

  navigate(event) {
    if (event.key !== "Enter" || event.isComposing) return
    event.preventDefault()
    const cell = this.element.closest("td")
    const row = cell.closest("tr")
    const next = event.shiftKey ? row.previousElementSibling : row.nextElementSibling
    const control = next?.querySelector(`[data-column="${CSS.escape(cell.dataset.column)}"] [data-journal-cell-control]`)
    this.submit()
    event.target.blur()
    control?.focus()
    control?.select?.()
  }
}
