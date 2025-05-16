import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]
  static outlets = ["upload"]

  connect() {
    this.bindEvents()
  }

  disconnect() {
    this.unbindEvents()
  }

  bindEvents() {
    ;["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      document.addEventListener(eventName, this.preventDefaults, false)
    })

    document.addEventListener("dragenter", this.showOverlay.bind(this))
    this.overlayTarget.addEventListener("dragleave", this.hideOverlay.bind(this))
    this.overlayTarget.addEventListener("drop", this.handleDrop.bind(this))
  }

  unbindEvents() {
    ;["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      document.removeEventListener(eventName, this.preventDefaults, false)
    })

    document.removeEventListener("dragenter", this.showOverlay.bind(this))
    this.overlayTarget.removeEventListener("dragleave", this.hideOverlay.bind(this))
    this.overlayTarget.removeEventListener("drop", this.handleDrop.bind(this))
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  showOverlay(e) {
    if (e.target === this.overlayTarget) return

    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
  }

  hideOverlay(e) {
    if (e.relatedTarget && this.overlayTarget.contains(e.relatedTarget)) return

    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
  }

  handleDrop(e) {
    this.hideOverlay(e)
    this.uploadOutlet.handleDrop(e)
  }
}
