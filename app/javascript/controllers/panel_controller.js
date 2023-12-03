import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uploadForm", "instantFilters"]

  toggleUploadForm() {
    if (this.uploadFormTarget.classList.contains("hidden")) {
      this.uploadFormTarget.classList.remove("hidden")
      this.instantFiltersTarget.classList.add("hidden")
    } else {
      this.uploadFormTarget.classList.add("hidden")
    }
  }

  toggleInstantFilters() {
    if (this.instantFiltersTarget.classList.contains("hidden")) {
      this.instantFiltersTarget.classList.remove("hidden")
      this.uploadFormTarget.classList.add("hidden")
    } else {
      this.instantFiltersTarget.classList.add("hidden")
    }
  }
}
