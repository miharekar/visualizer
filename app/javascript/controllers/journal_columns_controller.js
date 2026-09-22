import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "form", "list", "reset", "fields", "error"]

  connect() {
    this.snapshot = this.formTarget.innerHTML
  }

  disconnect() {
    this.finish()
  }

  toggle() {
    if (this.saving) return
    if (this.panelTarget.classList.contains("hidden")) this.panelTarget.classList.remove("hidden")
    else this.cancel()
  }

  cancel() {
    if (this.saving) return
    this.finish()
    this.formTarget.innerHTML = this.snapshot
    this.panelTarget.classList.add("hidden")
  }

  reset() {
    if (this.saving) return
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
    for (const input of this.formTarget.querySelectorAll('[name="columns[]"]')) {
      input.disabled = input.closest('[data-journal-columns-target="list"]').dataset.hidden === "true"
    }
  }

  savingStarted() {
    this.finish()
    this.saving = true
    this.fieldsTarget.disabled = true
    this.fieldsTarget.inert = true
  }

  savingEnded(event) {
    if (event.detail.success) return
    this.saving = false
    this.fieldsTarget.disabled = false
    this.fieldsTarget.inert = false
    this.errorTarget.textContent = "Not saved. Please try again."
  }

  start(event) {
    if (this.saving) return event.preventDefault()
    this.dragged = event.currentTarget.closest("[data-column]")
    event.dataTransfer.effectAllowed = "move"
    event.dataTransfer.setData("text/plain", this.dragged.dataset.column)
  }

  drag(event) {
    if (!this.dragged) return
    const element = event.target
    const list = element?.closest('[data-journal-columns-target="list"]')
    if (!this.listTargets.includes(list)) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"
    if (element.closest("[data-column]") === this.dragged) return
    const next = [...list.children].find(item => {
      if (item === this.dragged) return false
      const bounds = item.getBoundingClientRect()
      return event.clientY < bounds.top || (event.clientY <= bounds.bottom && event.clientX < bounds.left + bounds.width / 2)
    })
    if (this.dragged.parentElement !== list || this.dragged.nextElementSibling !== (next || null)) {
      this.resetTarget.disabled = true
      if (next) next.before(this.dragged)
      else list.append(this.dragged)
    }
  }

  drop(event) {
    if (!this.dragged) return
    event.preventDefault()
    this.finish()
  }

  finish() {
    this.dragged = null
  }
}
