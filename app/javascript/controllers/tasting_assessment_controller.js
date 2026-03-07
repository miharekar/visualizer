import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "value"]

  connect() {
    this.refresh()
  }

  update() {
    this.refresh()
  }

  refresh() {
    const hasAnyValue = this.sliderTargets.some((slider) => parseInt(slider.value, 10) > 0)

    this.sliderTargets.forEach((slider, index) => {
      this.valueTargets[index].textContent = slider.value

      if (hasAnyValue) {
        this.valueTargets[index].classList.remove("hidden")
      } else {
        this.valueTargets[index].classList.add("hidden")
      }
    })
  }
}
