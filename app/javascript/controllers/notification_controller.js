import { Controller } from "@hotwired/stimulus"
import { enter, leave } from "el-transition"

export default class extends Controller {
  static targets = ["notification"]

  connect() {
    enter(this.element)
    this.timeout = setTimeout(() => this.hideNotification(), 10000)
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
}
