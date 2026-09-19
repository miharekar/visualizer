import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "form", "list", "reset"]

  connect() {
    this.snapshot = this.formTarget.innerHTML
  }

  disconnect() {
    this.finish()
  }

  toggle() {
    if (this.panelTarget.classList.contains("hidden")) this.panelTarget.classList.remove("hidden")
    else this.cancel()
  }

  cancel() {
    this.finish()
    this.formTarget.innerHTML = this.snapshot
    this.panelTarget.classList.add("hidden")
  }

  reset() {
    this.finish()
    const [visible, hidden] = this.listTargets
    const items = [...this.formTarget.querySelectorAll("[data-column]")]
    items.forEach(item => hidden.append(item))
    for (const field of JSON.parse(this.panelTarget.dataset.defaults)) {
      visible.append(items.find(item => item.dataset.column === field))
    }
    this.resetTarget.disabled = false
  }

  serialize() {
    for (const input of this.formTarget.querySelectorAll('[name="hidden[]"]')) {
      input.disabled = input.closest('[data-journal-columns-target="list"]').dataset.hidden !== "true"
    }
  }

  start(event) {
    if (event.button !== 0 || !event.isPrimary) return
    event.preventDefault()
    this.finish()
    this.resetTarget.disabled = true
    this.dragged = event.currentTarget.closest("[data-column]")
    this.pointerId = event.pointerId
    const bounds = this.dragged.getBoundingClientRect()
    this.offset = { x: event.clientX - bounds.left, y: event.clientY - bounds.top }
    this.preview = this.dragged.cloneNode(true)
    this.preview.removeAttribute("data-column")
    this.preview.inert = true
    this.preview.classList.add("fixed", "top-0", "left-0", "z-50", "pointer-events-none", "shadow-lg")
    Object.assign(this.preview.style, { width: `${bounds.width}px`, height: `${bounds.height}px` })
    document.body.append(this.preview)
    this.movePreview(event)
    this.dragged.classList.add("opacity-50")
    this.dragPanel = this.panelTarget
    this.dragPanel.setPointerCapture(event.pointerId)
  }

  drag(event) {
    if (!this.dragged || event.pointerId !== this.pointerId) return
    this.movePreview(event)
    const element = document.elementFromPoint(event.clientX, event.clientY)
    const list = element?.closest('[data-journal-columns-target="list"]')
    if (!this.listTargets.includes(list)) return
    if (element.closest("[data-column]") === this.dragged) return
    const next = [...list.children].find(item => {
      if (item === this.dragged) return false
      const bounds = item.getBoundingClientRect()
      return event.clientY < bounds.top || (event.clientY <= bounds.bottom && event.clientX < bounds.left + bounds.width / 2)
    })
    if (next) next.before(this.dragged)
    else list.append(this.dragged)
  }

  movePreview(event) {
    this.preview.style.transform = `translate(${event.clientX - this.offset.x}px, ${event.clientY - this.offset.y}px)`
  }

  finish(event) {
    if (!this.dragged || (event && event.pointerId !== this.pointerId)) return
    this.dragged.classList.remove("opacity-50")
    this.preview.remove()
    this.preview = null
    this.dragged = null
    if (this.dragPanel.hasPointerCapture(this.pointerId)) this.dragPanel.releasePointerCapture(this.pointerId)
    this.dragPanel = null
    this.pointerId = null
  }
}
