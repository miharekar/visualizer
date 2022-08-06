import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["form"]

  submit() {
    clearTimeout(this.timeout)
    this.timeout = setTimeout(() => {
      Turbo.navigator.submitForm(this.formTarget)
    }, 200)
  }
}
