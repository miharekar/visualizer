import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drinkWeight", "beanWeight", "tds", "ey"]

  calculate() {
    const drinkWeight = this.getFloatFromString(this.drinkWeightTarget.value)
    const beanWeight = this.getFloatFromString(this.beanWeightTarget.value)
    const tds = this.getFloatFromString(this.tdsTarget.value)
    const ey = (drinkWeight * tds) / beanWeight
    this.eyTarget.value = ey.toFixed(2)
  }

  getFloatFromString(string) {
    return parseFloat(string.replace(",", ".").replace(" ", ""))
  }
}
