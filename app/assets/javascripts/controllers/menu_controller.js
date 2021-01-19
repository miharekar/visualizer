import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["toggleable"]

  toggle() {
    this.toggleableTargets.forEach((element) => {
      element.classList.toggle("hidden")
    })
  }
}
