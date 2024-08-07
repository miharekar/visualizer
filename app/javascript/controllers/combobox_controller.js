import { Controller } from "@hotwired/stimulus"
import { matchSorter } from "match-sorter"

export default class extends Controller {
  static targets = ["input", "hiddenInput", "list"]

  connect() {
    this.shown = false
    this.selected = this.listTarget.querySelector(".is-selected") || this.active
    this.allowCustom = this.element.hasAttribute("data-allow-custom")
  }

  show() {
    this.shown = true
    this.inputTarget.focus()
    this.listTarget.classList.remove("hidden")
    this.listTarget.scrollIntoView({ block: "nearest" })
    this.markAllAsInactive()
    this.active = this.selected
    this.filter()
  }

  hide(event) {
    if (!this.shown) return

    event.stopPropagation()
    this.shown = false
    if (this.selected && !this.allowCustom) this.inputTarget.value = this.selected.dataset.name
    this.listTarget.classList.add("hidden")
    this.inputTarget.blur()
  }

  windowClick(event) {
    if (this.shown && !this.element.contains(event.target)) {
      this.hide(event)
      event.stopPropagation()
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
    } else {
      this.inputTarget.value = ""
      this.show()
    }
  }

  filter() {
    const items = this.listTarget.querySelectorAll("li")
    const matches = matchSorter([...items], this.inputTarget.value, { keys: [item => item.dataset.name] })
    items.forEach((el) => {
      if (matches.includes(el)) {
        el.classList.remove("hidden")
      } else {
        el.classList.add("hidden")
        if (this.active === el) {
          this.active = null
          this.markAllAsInactive()
        }
      }
    })
  }

  select(event) {
    if (!this.shown) return
    event.preventDefault()

    if (this.listTarget.contains(event.currentTarget)) {
      this.active = event.currentTarget
    }

    let active = this.getActive()
    if (!active) return

    if (active === this.selected && !this.allowCustom) {
      this.hide(event)
      return
    }

    this.listTarget.querySelectorAll("li").forEach((el) => { el.classList.remove("is-selected") })
    this.selected = active
    this.selected.classList.add("is-selected")
    this.inputTarget.value = this.selected.dataset.name
    this.hiddenInputTarget.value = this.selected.dataset.id
    this.hiddenInputTarget.dispatchEvent(new Event("change"))
    this.hide(event)
  }

  mouseMove(event) {
    this.markAsActive(event.currentTarget)
  }

  highlightPrevious(event) {
    event.preventDefault()
    this.markAsActive(this.findPreviousVisibleElement())
  }

  highlightNext(event) {
    event.preventDefault()
    this.markAsActive(this.findNextVisibleElement())
  }

  markAsActive(element) {
    element = element || this.getActive()
    if (!element) return
    if (element.classList.contains("bg-terracotta-500")) return

    this.active = element
    this.markAllAsInactive()
    element.classList.remove("text-neutral-700", "dark:text-neutral-300")
    element.classList.add("text-white", "bg-terracotta-500", "dark:bg-terracotta-800")
    element.scrollIntoView({ block: "nearest" })
  }

  markAllAsInactive() {
    this.listTarget.querySelectorAll("li").forEach((el) => {
      el.classList.add("text-neutral-700", "dark:text-neutral-300")
      el.classList.remove("text-white", "bg-terracotta-500", "dark:bg-terracotta-800")
    })
  }

  findPreviousVisibleElement() {
    let element = this.getActive()
    while (element) {
      element = element.previousElementSibling
      if (element && !element.classList.contains("hidden")) return element
    }
  }

  findNextVisibleElement() {
    let element = this.getActive()
    while (element) {
      element = element.nextElementSibling
      if (element && !element.classList.contains("hidden")) return element
    }
  }

  getActive() {
    return this.active || this.listTarget.querySelector("li:not(.hidden)")
  }
}
