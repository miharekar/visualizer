import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "hiddenInput", "list"]

  connect() {
    this.shown = false
    this.selected = this.listTarget.querySelector(".is-selected") || this.listTarget.querySelector("li")
  }

  show() {
    this.shown = true
    this.inputTarget.focus()
    this.listTarget.classList.remove("hidden")
    this.markAllAsInactive()
    this.active = this.selected
    this.filter()
  }

  hide(event) {
    if (!this.shown) return

    event.stopPropagation()
    this.shown = false
    this.listTarget.classList.add("hidden")
  }

  windowClick(event) {
    if (this.shown && !this.element.contains(event.target)) {
      this.hide(event)
    }
  }

  blur(event) {
    if (event.relatedTarget && !this.element.contains(event.relatedTarget)) {
      this.hide(event)
    }
  }

  toggle(event) {
    if (this.shown) {
      this.hide(event)
      this.inputTarget.value = this.selected.dataset.roasterName
    } else {
      this.shown = true
      this.listTarget.classList.remove("hidden")
      this.listTarget.querySelectorAll("li").forEach((el) => { el.classList.remove("hidden") })
    }
  }

  highlight(event) {
    this.markAsActive(event.currentTarget)
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()
    this.listTarget.querySelectorAll("li").forEach((el) => {
      const name = el.dataset.roasterName.toLowerCase()
      if (name.includes(query)) {
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
        if (this.active === el) {
          this.active = null
        }
      }
    })
  }

  findPreviousVisibleElement(element) {
    while (element) {
      element = element.previousElementSibling
      if (element && !element.classList.contains('hidden')) {
        console.log("here")
        return element
      }
    }
  }

  findNextVisibleElement(element) {
    while (element) {
      element = element.nextElementSibling
      if (element && !element.classList.contains('hidden')) {
        return element
      }
    }
  }

  highlightPrevious(event) {
    if (!this.shown) this.show()

    event.stopPropagation()
    const previous = this.findPreviousVisibleElement(this.getActive()) || this.getActive()
    this.markAllAsInactive()
    this.markAsActive(previous)
  }

  highlightNext(event) {
    if (!this.shown) this.show()

    event.stopPropagation()
    const next = this.findNextVisibleElement(this.getActive()) || this.getActive()
    this.markAllAsInactive()
    this.markAsActive(next)
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

    let active = this.getActive()
    if (!active) return
    this.inputTarget.value = this.active.dataset.roasterName

    if (active === this.selected) {
      this.hide(event)
      return
    }

    this.listTarget.querySelectorAll("li").forEach((el) => { el.classList.remove("is-selected") })

    if (this.listTarget.contains(event.currentTarget)) {
      this.active = event.currentTarget
    }

    this.selected = active
    this.selected.classList.add("is-selected")
    this.hiddenInputTarget.value = this.selected.dataset.roasterId
    this.hiddenInputTarget.dispatchEvent(new Event("change"))
    this.hide(event)
  }

  getActive() {
    return this.active || this.listTarget.querySelector("li:not(.hidden)")
  }
}
