import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "list"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
  }

  visibility(event) {
    event.target.closest("[data-column]").querySelector('[name="hidden[]"]').disabled = event.target.checked
  }

  start(event) {
    if (event.button !== 0 || !event.isPrimary) return
    event.preventDefault()
    this.dragged = event.currentTarget.closest("[data-column]")
    this.dragged.classList.add("opacity-50")
    this.listTarget.setPointerCapture(event.pointerId)
  }

  drag(event) {
    if (!this.dragged) return
    const target = document.elementFromPoint(event.clientX, event.clientY)?.closest("[data-column]")
    if (!target || target === this.dragged || !this.listTarget.contains(target)) return
    const items = [...this.listTarget.children]
    if (items.indexOf(this.dragged) < items.indexOf(target)) target.after(this.dragged)
    else target.before(this.dragged)
  }

  finish(event) {
    if (!this.dragged) return
    this.dragged.classList.remove("opacity-50")
    this.dragged.querySelector("button").focus()
    this.dragged = null
    if (this.listTarget.hasPointerCapture(event.pointerId)) this.listTarget.releasePointerCapture(event.pointerId)
  }

  move(event) {
    const direction = { ArrowLeft: -1, ArrowUp: -1, ArrowRight: 1, ArrowDown: 1 }[event.key]
    if (!direction) return
    event.preventDefault()
    const item = event.currentTarget.closest("[data-column]")
    const neighbor = direction < 0 ? item.previousElementSibling : item.nextElementSibling
    if (direction < 0) neighbor?.before(item)
    else neighbor?.after(item)
    event.currentTarget.focus()
  }
}
