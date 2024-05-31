import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenInput", "list"]

  connect() {
    this.shown = false
  }

  show() {
    this.shown = true
    this.inputTarget.focus()
    this.listTarget.classList.remove("hidden")
    this.markAllAsInactive()
    this.selected = this.listTarget.querySelector(".is-selected") || this.listTarget.querySelector("li")
    this.active = this.selected
  }

  hide(event) {
    if (!this.shown) return

    event.stopPropagation()
    this.shown = false
    this.listTarget.classList.add("hidden")
  }

  blur(event) {
    if (event.relatedTarget && !this.element.contains(event.relatedTarget)) {
      this.hide(event)
    }
  }

  toggle(event) {
    this.shown ? this.hide(event) : this.show()
  }

  highlight(event) {
    this.markAsActive(event.currentTarget)
  }

  unhighlight(event) {
    this.markAllAsInactive(event.currentTarget)
  }

  highlightPrevious(event) {
    if (!this.shown) this.show()

    event.stopPropagation()
    const previous = this.active.previousElementSibling
    if (previous) {
      this.markAllAsInactive()
      this.markAsActive(previous)
    }
  }

  highlightNext(event) {
    if (!this.shown) this.show()

    event.stopPropagation()
    const next = this.active.nextElementSibling
    if (next) {
      this.markAllAsInactive()
      this.markAsActive(next)
    }
  }

  markAsActive(element) {
    this.active = element
    element.classList.remove("text-gray-900")
    element.classList.add("text-white", "bg-terracotta-500")
    element.scrollIntoView({ block: "nearest" })
  }

  markAllAsInactive() {
    this.listTarget.querySelectorAll("li").forEach((el) => {
      el.classList.add("text-gray-900")
      el.classList.remove("text-white", "bg-terracotta-500")
    })
  }

  select(event) {
    if (!this.shown) return

    event.preventDefault()
    this.listTarget.querySelectorAll("li").forEach((el) => { el.classList.remove("is-selected") })

    if (this.listTarget.contains(event.currentTarget)) {
      this.active = event.currentTarget
    }

    this.selected = this.active
    this.selected.classList.add("is-selected")
    this.inputTarget.value = this.selected.dataset.roasterName
    this.hiddenInputTarget.value = this.selected.dataset.roasterId
    this.hiddenInputTarget.dispatchEvent(new Event("change"))
    this.hide(event)
  }
}
