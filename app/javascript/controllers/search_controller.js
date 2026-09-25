import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    this.element.addEventListener("submit", this.cancel)
  }

  submit() {
    this.cancel()
    this.timeout = setTimeout(() => {
      this.formTarget.requestSubmit()
    }, 200)
  }

  cancel = () => clearTimeout(this.timeout)

  disconnect() {
    this.cancel()
    this.element.removeEventListener("submit", this.cancel)
  }
}
