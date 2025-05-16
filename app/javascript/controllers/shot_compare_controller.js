import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = ["checkbox", "banner"]

  initialize() {
    this.debouncedCheckState = debounce(() => this.checkState(), 10)
  }

  connect() {
    this.checkState()
  }

  checkboxTargetConnected() {
    this.debouncedCheckState()
  }

  select(event) {
    this.isChecked = event.target.checked
    this.baseId = this.isChecked ? event.target.value : null
    this.checkboxTargets.forEach(checkbox => {
      this.toggleComparing(checkbox.closest(".group"))
    })
    this.toggleBanner()
  }

  deselect(event) {
    this.isChecked = false
    this.baseId = null
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
      this.toggleComparing(checkbox.closest(".group"))
    })
    this.toggleBanner()
  }

  view(event) {
    if (this.isChecked) {
      event.preventDefault()
      const checkbox = event.target.closest(".group").querySelector("[data-shot-compare-target='checkbox']")
      if (checkbox.checked) {
        checkbox.checked = false
        this.select({ target: checkbox })
      } else {
        window.location.href = `/shots/${this.baseId}/compare/${checkbox.value}`
      }
    }
  }

  checkState() {
    const checkbox = this.checkboxTargets.find(checkbox => checkbox.checked)
    if (checkbox) {
      this.select({ target: checkbox })
    } else {
      this.isChecked = false
      this.toggleBanner()
    }
  }

  toggleComparing(shotRow) {
    if (this.isChecked) {
      shotRow.setAttribute("data-comparing", true)
    } else {
      shotRow.removeAttribute("data-comparing")
    }
  }

  toggleBanner() {
    if (this.isChecked) {
      this.bannerTarget.classList.remove("hidden")
    } else {
      this.bannerTarget.classList.add("hidden")
    }
  }
}
