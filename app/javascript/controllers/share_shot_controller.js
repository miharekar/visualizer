import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { enter, leave } from "el-transition"

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
      this.toggleableTargets.forEach((element) => {
        enter(element)
      })
    }
    this.modalShown = true
  }

  getCode() {
    if (this.code.length == 0) {
      fetch(this.urlValue).then((response) => {
        response.json().then(data => {
          this.code = data.code
          this.codeTarget.innerText = this.code
        })
      })
    }
  }

  hide() {
    if (this.modalShown) {
      this.toggleableTargets.forEach((element) => {
        leave(element)
      })
    }
    this.modalShown = false
  }

  keydown(event) {
    if (this.modalShown) {
      if (event.keyCode == 27) {
        event.preventDefault()
        this.hide()
      } else if (event.keyCode == 13) {
        event.preventDefault()
        this.delete()
      }
    }
  }
}
