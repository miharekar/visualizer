import { Controller } from "@hotwired/stimulus"
import { enter, leave } from "el-transition"

export default class extends Controller {
  static targets = ["notification"]
  static values = { timeout: { type: Number, default: 10000 } }

  connect() {
    if (!this.parentHidden()) {
      enter(this.element)
      this.timeout = setTimeout(() => this.hideNotification(), this.timeoutValue)
    }
  }

  close(event) {
    event.preventDefault()
    this.hideNotification()
  }

  hideNotification() {
    clearTimeout(this.timeout)
    leave(this.element).then(() => {
      this.element.remove()
    })
  }

  parentHidden() {
    return this.element.parentElement.classList.contains('hidden')
  }
}
