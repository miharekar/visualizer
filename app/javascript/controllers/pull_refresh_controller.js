import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["indicator"]
  static values = { threshold: { type: Number, default: 80 } }

  connect() {
    this.enabled = this.#isStandalonePwa() && this.#supportsTouch()
    this.dragging = false
    this.refreshing = false
    this.startY = 0
    this.pullDistance = 0
    this.#setProgress(0)
  }

  touchstart(event) {
    if (!this.enabled || this.refreshing || !this.#isAtTop()) return

    this.dragging = true
    this.startY = event.touches[0].clientY
    this.pullDistance = 0
  }

  touchmove(event) {
    if (!this.dragging || this.refreshing) return

    const currentY = event.touches[0].clientY
    const rawDistance = currentY - this.startY

    if (rawDistance <= 0) return this.#reset()

    if (!this.#isAtTop()) return this.#reset()

    this.pullDistance = Math.min(rawDistance * 0.5, this.thresholdValue * 1.5)
    this.#render()

    if (this.pullDistance > 0) event.preventDefault()
  }

  touchend() {
    if (!this.dragging || this.refreshing) return

    this.dragging = false

    if (this.pullDistance >= this.thresholdValue) {
      this.refreshing = true
      this.#setProgress(1)
      window.location.reload()
      return
    }

    this.#reset()
  }

  touchcancel() {
    this.#reset()
  }

  #render() {
    this.#setProgress(Math.min(this.pullDistance / this.thresholdValue, 1))
  }

  #reset() {
    this.dragging = false
    this.pullDistance = 0
    this.refreshing = false
    this.#setProgress(0)
  }

  #setProgress(progress) {
    this.indicatorTarget.classList.toggle("opacity-0", progress === 0)
    this.indicatorTarget.style.setProperty("--pull-progress", progress.toFixed(3))
  }

  #isAtTop() {
    return (document.scrollingElement?.scrollTop || window.scrollY || 0) <= 0
  }

  #isStandalonePwa() {
    return window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true
  }

  #supportsTouch() {
    return window.matchMedia("(pointer: coarse)").matches || navigator.maxTouchPoints > 0
  }
}
