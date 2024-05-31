import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["coffeeBags"]

  roaster_changed(event) {
    if (event.currentTarget.value === "new") {
      Turbo.visit(this.element.dataset.newRoasterPath)
    } else {
      const frame = document.getElementById("coffee_bag_fields")
      let url = this.element.dataset.coffeeBagFormShotsPath
      const separator = url.includes('?') ? '&' : '?'
      url += `${separator}roaster_id=${event.currentTarget.value}`
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
