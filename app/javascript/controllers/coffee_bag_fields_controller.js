import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["roasters", "coffeeBags"]

  roaster_changed() {

    if (this.roastersTarget.value === "new") {
      Turbo.visit(this.element.dataset.newRoasterPath)
    } else {
      const frame = document.getElementById("coffee_bag_fields")
      let url = this.roastersTarget.dataset.url
      const separator = url.includes('?') ? '&' : '?'
      url += `${separator}roaster=${this.roastersTarget.value}`
      frame.src = url
      frame.reload()
    }
  }


  coffee_bag_changed() {
    if (this.coffeeBagsTarget.value === "new") {
      Turbo.visit(this.element.dataset.newCoffeeBagPath)
    }
  }
}
