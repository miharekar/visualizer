import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]
  static outlets = ["upload"]

  initialize() {
    this.showOverlay = this.showOverlay.bind(this)
    this.hideOverlay = this.hideOverlay.bind(this)
    this.handleDrop = this.handleDrop.bind(this)
  }

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

    document.addEventListener("dragenter", this.showOverlay)
    this.overlayTarget.addEventListener("dragleave", this.hideOverlay)
    this.overlayTarget.addEventListener("drop", this.handleDrop)
  }

  unbindEvents() {
    ;["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
      document.removeEventListener(eventName, this.preventDefaults, false)
    })

    document.removeEventListener("dragenter", this.showOverlay)
    this.overlayTarget.removeEventListener("dragleave", this.hideOverlay)
    this.overlayTarget.removeEventListener("drop", this.handleDrop)
  }

  preventDefaults(e) {
    if (!e.dataTransfer.types.includes("Files")) return
    e.preventDefault()
    e.stopPropagation()
  }

  showOverlay(e) {
    if (!e.dataTransfer.types.includes("Files") || e.target === this.overlayTarget) return

    this.overlayTarget.classList.remove("hidden")
    this.overlayTarget.classList.add("flex")
  }

  hideOverlay(e) {
    if (e.relatedTarget && this.overlayTarget.contains(e.relatedTarget)) return

    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.remove("flex")
  }

  handleDrop(e) {
    if (!e.dataTransfer.types.includes("Files")) return
    this.hideOverlay(e)
    this.uploadOutlet.handleDrop(e)
  }
}
