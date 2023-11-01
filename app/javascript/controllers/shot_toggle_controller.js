import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["switch", "shots"]
  static values = { initialStatus: Boolean }

  connect() {
    this.switchStatus = this.initialStatusValue || false
  }

  toggle() {
    this.switchStatus = !this.switchStatus
    this.apply()
  }

  apply() {
    if (this.switchStatus) {
      this.switchTarget.innerHTML = "Contract"
      this.shotsTarget.classList.remove("hidden")
    } else {
      this.switchTarget.innerHTML = "Expand"
      this.shotsTarget.classList.add("hidden")
    }
  }
}
