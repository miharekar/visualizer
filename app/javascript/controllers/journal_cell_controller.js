import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  connect() {
    this.failed = this.element.hasAttribute("data-unsaved")
  }

  dirty() {
    this.element.toggleAttribute("data-unsaved", this.failed || this.inputTarget.value !== this.inputTarget.defaultValue || this.inputTarget.validity.badInput)
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
    this.failed = true
    this.element.dataset.unsaved = ""
    this.inputTarget.readOnly = false
    this.errorTarget.textContent = "Not saved. Press Enter to retry."
  }

  navigate(event) {
    if (event.key !== "Enter" || event.isComposing) return
    event.preventDefault()
    if (this.element.hasAttribute("data-unsaved") && !this.submit()) return
    const cell = this.element.closest("td")
    const step = event.shiftKey ? "previousElementSibling" : "nextElementSibling"
    const selector = `[data-column="${CSS.escape(cell.dataset.column)}"] [data-journal-cell-control]`
    let control = null
    for (let row = cell.parentElement[step]; row && !control; row = row[step]) control = row.querySelector(selector)
    control?.focus()
    control?.select?.()
  }
}
