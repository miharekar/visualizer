import { Controller } from "@hotwired/stimulus"
import { enter, leave } from "el-transition"

const KEY_ACTIONS = {
  Escape(controller) {
    controller.hide()
  },
  Enter(controller) {
    controller.performClick()
  }
}

export default class extends Controller {
  static targets = ["toggleable", "headline", "text", "button"]

  initialize() {
    this.modalShown = false
    this.preventClick = true
  }

  confirm(event) {
    if (this.preventClick) {
      event.preventDefault()
      this.currentTarget = event.currentTarget
      const data = event.currentTarget.dataset
      this.headlineTarget.innerText = data.title
      this.buttonTarget.innerText = data.title
      this.textTarget.innerText = data.text
      this.show()
    }
  }

  show() {
    if (!this.modalShown) {
      this.toggleableTargets.forEach(element => enter(element))
    }
    this.modalShown = true
  }

  hide() {
    if (this.modalShown) {
      this.toggleableTargets.forEach(element => leave(element))
    }
    this.modalShown = false
  }

  performClick() {
    this.preventClick = false
    this.currentTarget.click()
    this.hide()
    this.preventClick = true
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
