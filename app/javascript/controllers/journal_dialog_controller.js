import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fields", "error"]

  connect() {
    this.element.showModal()
  }

  start() {
    this.submitting = true
    this.fieldsTarget.disabled = true
    this.fieldsTarget.inert = true
    this.element.setAttribute("closedby", "none")
  }

  complete(event) {
    if (event.detail.fetchResponse?.contentType?.includes("turbo-stream")) return
    this.submitting = false
    this.fieldsTarget.disabled = false
    this.fieldsTarget.inert = false
    this.element.setAttribute("closedby", "any")
    this.errorTarget.textContent = "Not saved. Please try again."
  }

  cancel(event) {
    if (this.submitting) event.preventDefault()
  }

  close() {
    if (this.submitting) return
    this.element.close()
  }

  remove() {
    this.element.remove()
  }
}
