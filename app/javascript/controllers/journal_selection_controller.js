import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "all", "toolbar", "count", "notice", "compare"]

  get selected() {
    return this.checkboxTargets.filter(input => input.checked)
  }

  checkboxTargetConnected() {
    this.select()
  }

  checkboxTargetDisconnected() {
    this.select()
  }

  select(event) {
    if (!this.hasCountTarget || !this.hasAllTarget) return
    if (event?.target.checked && this.selected.length > 100) event.target.checked = false
    const selected = this.selected
    const count = selected.length
    this.countTarget.textContent = `${count} selected`
    this.noticeTarget.textContent = count === 100 ? "Maximum 100 shots per edit" : ""
    this.toolbarTarget.classList.toggle("hidden", count === 0)
    this.toolbarTarget.classList.toggle("flex", count > 0)
    this.compareTarget.classList.toggle("hidden", count !== 2)
    if (count === 2) this.compareTarget.href = `/shots/${selected[0].value}/compare/${selected[1].value}`
    this.allTarget.checked = count > 0 && count === this.checkboxTargets.length
    this.allTarget.indeterminate = count > 0 && count < this.checkboxTargets.length
  }

  selectAll(event) {
    this.checkboxTargets.forEach((input, index) => {
      input.checked = event.target.checked && index < 100
    })
    this.select()
  }

  reset() {
    this.checkboxTargets.forEach(input => (input.checked = false))
    this.select()
  }
}
