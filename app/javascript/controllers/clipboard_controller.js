import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "copy", "check", "container"]

  copy(event) {
    event.preventDefault()

    this.sourceTarget.classList.remove("hidden")
    this.sourceTarget.select()
    document.execCommand("copy")
    this.sourceTarget.classList.add("hidden")

    this.copyTarget.classList.add("hidden")
    this.checkTarget.classList.remove("hidden")
    this.containerTarget.classList.add("bg-green-200", "hover:bg-green-200", "dark:bg-green-700", "dark:hover:bg-green-700")
    setTimeout(() => {
      this.resetState()
    }, 2000)
  }

  resetState() {
    this.containerTarget.classList.add("transition", "duration-1000")
    this.containerTarget.classList.remove("bg-green-200", "hover:bg-green-200", "dark:bg-green-700", "dark:hover:bg-green-700")
    this.copyTarget.classList.remove("hidden")
    this.checkTarget.classList.add("hidden")
    setTimeout(() => {
      this.removeTransition()
    }, 1000)
  }

  removeTransition() {
    this.containerTarget.classList.remove("transition", "duration-1000")
  }
}
