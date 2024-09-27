import { Controller } from "@hotwired/stimulus"
import { matchSorter } from "match-sorter"

export default class extends Controller {
  static targets = ["input", "hiddenInput", "list"]

  static values = {
    allowCustom: { type: Boolean, default: false },
    activeClasses: { type: Array, default: ["bg-terracotta-500", "dark:bg-terracotta-800", "text-white"] },
    inactiveClasses: { type: Array, default: ["text-neutral-700", "dark:text-neutral-300"] },
    hiddenClass: { type: String, default: "hidden" },
    selectedClass: { type: String, default: "is-selected" }
  }

  connect() {
    this.shown = false
    this.selected = this.listTarget.querySelector(`.${this.selectedClassValue}`) || this.active
    this.allItems = Array.from(this.listTarget.querySelectorAll("li"))
    this.listTarget.innerHTML = ""
  }

  show() {
    if (this.shown) return

    this.shown = true
    this.inputTarget.focus()
    this.listTarget.classList.remove(this.hiddenClassValue)
    this.listTarget.scrollIntoView({ block: "nearest" })
    this.markAllAsInactive()
    this.active = this.selected
    this.filter()
  }

  hide(event) {
    if (!this.shown) return

    event.stopPropagation()
    this.shown = false

    if (this.allowCustomValue) {
      if (this.selected?.dataset.name !== this.inputTarget.value) {
        this.selected = null
      }
    } else {
      if (this.selected) {
        this.inputTarget.value = this.selected.dataset.name
      } else {
        this.inputTarget.value = ""
      }
    }

    this.markAllAsUnselected()
    this.listTarget.classList.add(this.hiddenClassValue)
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
    this.show()
    const sortedMatches = matchSorter(this.allItems, this.inputTarget.value, { keys: [item => item.dataset.name] })

    const matchesHtml = sortedMatches
      .map(el => this.listTarget.appendChild(el).outerHTML)
      .join("")

    this.listTarget.innerHTML = matchesHtml

    if (this.active && !sortedMatches.includes(this.active)) {
      this.active = null
      this.markAllAsInactive()
    }
  }

  select(event) {
    if (!this.shown) return
    event.preventDefault()

    if (this.listTarget.contains(event.currentTarget)) {
      this.active = event.currentTarget
    }

    let active = this.getActive()
    if (!active) return

    if (active !== this.selected) {
      this.selected = active
      this.inputTarget.value = this.selected.dataset.name
      this.hiddenInputTarget.value = this.selected.dataset.id
      this.hiddenInputTarget.dispatchEvent(new Event("change"))
    }

    this.hide(event)
  }

  mouseMove(event) {
    this.markAsActive(event.currentTarget)
  }

  highlightNext(event) {
    event.preventDefault()

    if (this.active) {
      this.markAsActive(this.findNextVisibleElement())
    } else {
      this.markAsActive(this.getActive())
    }
  }

  highlightPrevious(event) {
    event.preventDefault()
    this.markAsActive(this.findPreviousVisibleElement())
  }

  markAsActive(element) {
    element = element || this.getActive()
    if (!element) return
    if (element.classList.contains(this.activeClassesValue[1])) return

    this.active = element
    this.markAllAsInactive()
    element.classList.remove(...this.inactiveClassesValue)
    element.classList.add(...this.activeClassesValue)
    element.scrollIntoView({ block: "nearest" })
  }

  markAllAsInactive() {
    this.listTarget.querySelectorAll("li").forEach((el) => {
      el.classList.add(...this.inactiveClassesValue)
      el.classList.remove(...this.activeClassesValue)
    })
  }

  findPreviousVisibleElement() {
    let element = this.getActive()
    while (element) {
      element = element.previousElementSibling
      if (element && !element.classList.contains(this.hiddenClassValue)) return element
    }
  }

  findNextVisibleElement() {
    let element = this.getActive()
    while (element) {
      element = element.nextElementSibling
      if (element && !element.classList.contains(this.hiddenClassValue)) return element
    }
  }

  getActive() {
    let activeId = this.active?.dataset.id
    if (activeId) return this.listTarget.querySelector(`[data-id="${activeId}"]`)
    return this.listTarget.querySelector(`li:not(.${this.hiddenClassValue})`)
  }

  markAllAsUnselected() {
    this.listTarget.querySelectorAll("li").forEach((el) => { el.classList.remove(this.selectedClassValue) })
    this.allItems.forEach(item => {
      item.classList[item.dataset.id === this.selected?.dataset.id ? "add" : "remove"](this.selectedClassValue)
    })
  }
}
