import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  hide() {
    this.element.classList.add("hidden")
  }
}
