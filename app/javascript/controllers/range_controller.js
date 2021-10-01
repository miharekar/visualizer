import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["number", "range", "color", "text"]

  update(event) {
    var value = parseInt(event.currentTarget.value)
    value = value > 100 ? 100 : value
    value = value < 0 ? 0 : value
    const hsl = 124 / 100 * parseInt(value)
    if (this.hasNumberTarget) {
      this.numberTarget.value = value
      this.numberTarget.style.backgroundColor = "hsl(" + hsl + ", 70%, 50%)"
    }
    if (this.hasRangeTarget) {
      this.rangeTarget.value = value
    }
    if (this.hasTextTarget) {
      this.textTarget.innerHTML = value
    }
    if (this.hasColorTarget) {
      this.colorTarget.style.backgroundColor = "hsl(" + hsl + ", 70%, 50%)"
    }
  }
}
