import { Controller } from "@hotwired/stimulus"
import { enter, leave } from "el-transition"

const KEY_ACTIONS = {
  Escape(controller) {
    controller.hide()
  },
  Enter(controller) {
    controller.hide()
  }
}

export default class extends Controller {
  static targets = ["toggleable", "code"]
  static values = { url: String }

  initialize() {
    this.modalShown = false
    this.code = ""
  }

  show() {
    if (!this.modalShown) {
      this.getCode()
      this.toggleableTargets.forEach(el => enter(el))
    }
    this.modalShown = true
  }

  getCode() {
    if (this.code.length === 0) {
      fetch(this.urlValue)
        .then(r => r.json())
        .then(data => {
          this.code = data.code
          this.codeTarget.innerText = this.code
        })
    }
  }

  hide() {
    if (this.modalShown) {
      this.toggleableTargets.forEach(el => leave(el))
    }
    this.modalShown = false
  }

  backgroundClick(event) {
    if (event.target && !event.target.closest("button")) {
      this.hide()
    }
  }

  keydown(event) {
    if (!this.modalShown) return

    const action = KEY_ACTIONS[event.key]
    if (!action) return

    event.preventDefault()
    action(this)
  }
}
