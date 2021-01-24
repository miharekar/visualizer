
import { Controller } from "stimulus"
import { enter, leave } from "el-transition";

export default class extends Controller {
  static targets = ["toggleable", "headline", "text", "button"]

  initialize() {
    this.modalShown = false
  }

  confirm(event) {
    event.preventDefault()
    this.form = event.target.parentElement
    const data = event.target.dataset
    this.headlineTarget.innerText = data.title
    this.buttonTarget.innerText = data.title
    this.textTarget.innerText = data.text
    this.show()
  }

  show() {
    if (!this.modalShown) {
      this.toggleableTargets.forEach((element) => {
        enter(element)
      })
    }
    this.modalShown = true
  }

  hide() {
    if (this.modalShown) {
      this.toggleableTargets.forEach((element) => {
        leave(element)
      })
    }
    this.modalShown = false
  }

  delete() {
    this.form.requestSubmit()
    this.hide()
  }

  close(event) {
    if (event.keyCode == 27) {
      this.hide()
    }
  }
}