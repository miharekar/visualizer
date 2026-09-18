import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["uploadForm", "uploadButton", "instantFilters"]

  connect() {
    if (this.hasUploadButtonTarget) this.uploadButtonTarget.setAttribute("aria-expanded", String(!this.uploadFormTarget.classList.contains("hidden")))
  }

  toggleUploadForm() {
    if (this.uploadFormTarget.classList.contains("hidden")) {
      this.uploadFormTarget.classList.remove("hidden")
      if (this.hasInstantFiltersTarget) this.instantFiltersTarget.classList.add("hidden")
    } else {
      this.uploadFormTarget.classList.add("hidden")
    }
    if (this.hasUploadButtonTarget) this.uploadButtonTarget.setAttribute("aria-expanded", String(!this.uploadFormTarget.classList.contains("hidden")))
  }

  toggleInstantFilters() {
    if (this.instantFiltersTarget.classList.contains("hidden")) {
      if (this.hasInstantFiltersTarget) this.instantFiltersTarget.classList.remove("hidden")
      this.uploadFormTarget.classList.add("hidden")
      if (this.hasUploadButtonTarget) this.uploadButtonTarget.setAttribute("aria-expanded", "false")
    } else {
      this.instantFiltersTarget.classList.add("hidden")
    }
  }
}
