import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]

  connect() {
    this.updateCounter()
  }

  updateCounter() {
    const count = this.inputTarget.value.length
    const max = this.inputTarget.maxLength

    this.counterTarget.textContent = count

    this.counterTarget.classList.remove("text-red-500", "text-yellow-500")
    if (count == max) {
      this.counterTarget.classList.add("text-red-500")
    } else if (count / max > 0.8) {
      this.counterTarget.classList.add("text-yellow-500")
    }
  }
}
