import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "autocomplete", "roaster", "coffeeBag", "id"]

  connect() {
    this.autocompleteTarget.addEventListener("search", this.changed.bind(this))
    this.autocompleteTarget.addEventListener("change", this.changed.bind(this))
    this.autocompleteTarget.addEventListener("autocomplete.change", this.autocompleted.bind(this))

    if (this.idTarget.value != "") {
      this.disableInputs()
    }
  }

  autocompleted(event) {
    this.roasterTarget.value = event.detail.selected.dataset.roaster
    this.coffeeBagTarget.value = event.detail.selected.dataset.coffeeBag
    this.disableInputs()
  }

  changed() {
    this.enableInputs()
  }

  disableInputs() {
    for (const el of [this.roasterTarget, this.coffeeBagTarget]) {
      el.disabled = true
      el.classList.add("opacity-50", "cursor-not-allowed")
    }
  }

  enableInputs() {
    for (const el of [this.roasterTarget, this.coffeeBagTarget]) {
      el.disabled = false
      el.classList.remove("opacity-50", "cursor-not-allowed")
    }
  }
}
