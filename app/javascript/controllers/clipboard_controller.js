import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "copy", "check", "container"]

  async copy(event) {
    event.preventDefault()
    if (this.copying) return
    this.copying = true

    const notificationsContainer = document.getElementById("notifications-container")

    try {
      await navigator.clipboard.writeText(this.sourceTarget.value)
    } catch {
      this.copying = false
      notificationsContainer.insertAdjacentHTML("beforeend", document.getElementById("clipboard-error").innerHTML)
      return
    }

    this.copyTarget.classList.add("hidden")
    this.checkTarget.classList.remove("hidden")
    this.containerTarget.classList.add("bg-green-200", "hover:bg-green-200", "dark:bg-green-700", "dark:hover:bg-green-700")

    const successNotification = document.getElementById("clipboard-success")
    notificationsContainer.insertAdjacentHTML("beforeend", successNotification.innerHTML)

    setTimeout(() => {
      this.resetState()
    }, 2000)
  }

  resetState() {
    this.copying = false
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
