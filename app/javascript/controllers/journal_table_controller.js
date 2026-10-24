import { Controller } from "@hotwired/stimulus"
import { patch } from "@rails/request.js"

export default class extends Controller {
  static values = { url: String }

  dirty(event) {
    const input = this.input(event)
    if (!input) return
    const cell = input.closest("td")
    cell.toggleAttribute("data-unsaved", cell.hasAttribute("data-failed") || input.value !== input.defaultValue || input.validity.badInput)
    if (cell.dataset.column === "espresso_enjoyment") this.recolor(input)
  }

  save(event) {
    const input = this.input(event)
    if (input) this.submit(input)
  }

  navigate(event) {
    const input = this.input(event)
    if (!input || event.key !== "Enter" || event.isComposing) return
    event.preventDefault()
    const cell = input.closest("td")
    if (cell.hasAttribute("data-unsaved") && !this.submit(input)) return
    const step = event.shiftKey ? "previousElementSibling" : "nextElementSibling"
    const selector = `[data-column="${CSS.escape(cell.dataset.column)}"] [data-journal-cell-control]`
    let control = null
    for (let row = cell.parentElement[step]; row && !control; row = row[step]) control = row.querySelector(selector)
    control?.focus()
    control?.select?.()
  }

  input(event) {
    return event.target.matches?.('td[data-column] input[name="value"]') ? event.target : null
  }

  recolor(input) {
    const value = parseInt(input.value)
    if (!Number.isNaN(value)) input.style.backgroundColor = `hsl(${1.2 * Math.min(Math.max(value, 0), 100)}, 70%, 50%)`
  }

  submit(input) {
    const cell = input.closest("td")
    if (cell.hasAttribute("data-saving")) return true
    if (!input.reportValidity()) return false
    cell.dataset.saving = ""
    input.readOnly = true
    cell.querySelector(":scope > p")?.remove()
    this.send(cell, input)
    return true
  }

  async send(cell, input) {
    try {
      const response = await patch(this.url(cell), { body: new URLSearchParams({ value: input.value }).toString(), contentType: "application/x-www-form-urlencoded", responseKind: "turbo-stream" })
      if (response.isTurboStream && (response.ok || response.unprocessableEntity)) return
    } catch {}
    this.fail(cell, input)
  }

  url(cell) {
    const params = new URLSearchParams({ field: cell.dataset.column })
    params.append("ids[]", cell.closest("tr").dataset.id)
    return `${this.urlValue}?${params}`
  }

  fail(cell, input) {
    if (!cell.isConnected) return
    delete cell.dataset.saving
    cell.dataset.failed = ""
    cell.dataset.unsaved = ""
    input.readOnly = false
    let error = cell.querySelector(":scope > p")
    if (!error) {
      error = document.createElement("p")
      error.className = "px-2 text-sm text-red-600 dark:text-red-400"
      cell.append(error)
    }
    error.textContent = "Not saved. Press Enter to retry."
  }
}
