import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roasters"]

  fetch() {
    const roaster = this.roastersTarget.value
    const frame = document.getElementById("coffee_bag_fields")
    frame.src = this.roastersTarget.dataset.url + `?roaster=${roaster}`
    frame.reload()
  }
}
