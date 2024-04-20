import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["roasters"]

  fetch() {
    const optionUrl = this.roastersTarget.options[this.roastersTarget.selectedIndex].dataset.url
    if (optionUrl !== undefined) {
      Turbo.visit(optionUrl)
    } else {
      const roaster = this.roastersTarget.value
      const frame = document.getElementById("coffee_bag_fields")
      frame.src = this.roastersTarget.dataset.url + `?roaster=${roaster}`
      frame.reload()
    }
  }
}
