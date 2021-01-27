import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["number", "color"]

  update(event) {
    const value = event.currentTarget.value
    this.numberTarget.innerHTML = value
    this.colorTarget.style.backgroundColor = "hsl(" + (124 / 100 * parseInt(value)) + ", 70%, 50%)"
  }
}
