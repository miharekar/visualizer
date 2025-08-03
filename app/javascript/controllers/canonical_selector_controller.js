import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["autocomplete", "roaster", "coffeeBag", "id"]

  connect() {
    this.toggleInputs()

    this.autocompleteTarget.addEventListener("autocomplete.change", this.autocompleted.bind(this))
    this.observer = new MutationObserver(() => this.toggleInputs())
    this.observer.observe(this.idTarget, { attributes: true, attributeFilter: ["value"] })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  autocompleted(event) {
    this.roasterTarget.value = event.detail.selected.dataset.roaster
    this.coffeeBagTarget.value = event.detail.selected.dataset.coffeeBag
    this.toggleInputs()
  }

  toggleInputs() {
    const disabled = Boolean(this.idTarget.value)
    this.roasterTarget.disabled = this.coffeeBagTarget.disabled = disabled
    this.roasterTarget.classList.toggle("cursor-not-allowed", disabled)
    this.coffeeBagTarget.classList.toggle("cursor-not-allowed", disabled)
  }
}
