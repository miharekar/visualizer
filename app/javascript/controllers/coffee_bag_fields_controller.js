import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["roasters"]

  fetch() {
    const roaster = this.roastersTarget.value
    if (roaster === "new") {
      Turbo.visit(this.element.dataset.newRoasterPath)
    } else {
      const frame = document.getElementById("coffee_bag_fields")
      frame.src = this.roastersTarget.dataset.url + `&roaster=${roaster}`
      frame.reload()
    }
  }
}
