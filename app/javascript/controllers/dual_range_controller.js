import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["min", "max", "minValue", "maxValue"]

  connect() {
    this.update()
  }

  update(event) {
    const min = parseInt(this.minTarget.value)
    const max = parseInt(this.maxTarget.value)

    if (min > max) {
      if (event?.currentTarget === this.minTarget) {
        this.minTarget.value = max
      } else {
        this.maxTarget.value = min
      }
    }

    if (this.hasMinValueTarget) this.minValueTarget.textContent = this.minTarget.value
    if (this.hasMaxValueTarget) this.maxValueTarget.textContent = this.maxTarget.value
  }
}
