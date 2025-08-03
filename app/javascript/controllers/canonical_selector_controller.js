import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "autocomplete", "roaster", "coffeeBag", "id"]

  connect() {
    this.autocompleteTarget.addEventListener("change", this.toggleInputs.bind(this))
    this.autocompleteTarget.addEventListener("autocomplete.change", this.autocompleted.bind(this))

    this.toggleInputs()
  }

  autocompleted(event) {
    this.roasterTarget.value = event.detail.selected.dataset.roaster
    this.coffeeBagTarget.value = event.detail.selected.dataset.coffeeBag
    this.toggleInputs()
  }

  toggleInputs() {
    const disabled = !!this.idTarget.value
    for (const el of [this.roasterTarget, this.coffeeBagTarget]) {
      el.disabled = disabled
      el.classList.toggle("cursor-not-allowed", disabled)
    }
  }
}
