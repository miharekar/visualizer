import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  roaster_changed(event) {
    const frame = document.getElementById("coffee_bag_fields")
    let url = this.element.dataset.coffeeBagFormShotsPath
    const separator = url.includes('?') ? '&' : '?'
    url += `${separator}roaster_id=${event.currentTarget.value}`
    frame.src = url
    frame.reload()
  }
}
