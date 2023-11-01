import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["switch", "onIcon", "offIcon"]
  static values = { initialStatus: Boolean }

  connect() {
    this.switchStatus = this.initialStatusValue || false
    this.apply()
  }

  toggle() {
    this.switchStatus = !this.switchStatus
    this.apply()
  }

  apply() {
    if (this.switchStatus) {
      this.switchTarget.classList.replace("translate-x-0", "translate-x-5")
      this.switchTarget.parentElement.classList.replace("bg-neutral-200", "bg-oxford-blue-600")
      this.onIconTarget.classList.replace("opacity-0", "opacity-100")
      this.onIconTarget.classList.replace("duration-100", "duration-200")
      this.onIconTarget.classList.replace("ease-out", "ease-in")

      this.offIconTarget.classList.replace("opacity-100", "opacity-0")
      this.offIconTarget.classList.replace("duration-200", "duration-100")
      this.offIconTarget.classList.replace("ease-in", "ease-out")
    } else {
      this.switchTarget.classList.replace("translate-x-5", "translate-x-0")
      this.switchTarget.parentElement.classList.replace("bg-oxford-blue-600", "bg-neutral-200")
      this.onIconTarget.classList.replace("opacity-100", "opacity-0")
      this.onIconTarget.classList.replace("duration-200", "duration-100")
      this.onIconTarget.classList.replace("ease-in", "ease-out")

      this.offIconTarget.classList.replace("opacity-0", "opacity-100")
      this.offIconTarget.classList.replace("duration-100", "duration-200")
      this.offIconTarget.classList.replace("ease-out", "ease-in")
    }
  }
}
