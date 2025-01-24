import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  connect() {
    const checkbox = this.checkboxTargets.find(checkbox => checkbox.checked)
    if (checkbox) {
      this.select({ target: checkbox })
    }
  }

  checkboxTargetConnected(checkbox) {
    this.toggleComparing(checkbox.closest(".group"))
  }

  select(event) {
    this.isChecked = event.target.checked
    this.baseId = this.isChecked ? event.target.value : null
    this.checkboxTargets.forEach(checkbox => {
      this.toggleComparing(checkbox.closest(".group"))
    })
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

  toggleComparing(shotRow) {
    if (this.isChecked) {
      shotRow.setAttribute('data-comparing', true)
    } else {
      shotRow.removeAttribute('data-comparing')
    }
  }
}
