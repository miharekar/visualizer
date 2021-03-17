import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["source", "hideable"]

  display() {
    const display = this.sourceTarget.checked
    this.hideableTargets.forEach((element) => {
      if (display) {
        element.classList.remove("hidden")
      } else {
        element.classList.add("hidden")
      }
    })
  }
}
