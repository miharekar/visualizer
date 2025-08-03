import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roaster", "coffeeBag", "id"]

  connect() {
    this.toggleInputs()

    this.observer = new MutationObserver(() => this.toggleInputs())
    this.observer.observe(this.idTarget, { attributes: true, attributeFilter: ["value"] })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  autocompleted({ detail }) {
    const { roaster, coffeeBag } = detail.selected.dataset
    this.roasterTarget.value = roaster
    this.coffeeBagTarget.value = coffeeBag
  }

  toggleInputs() {
    const disabled = Boolean(this.idTarget.value)
    this.roasterTarget.disabled = this.coffeeBagTarget.disabled = disabled
    this.roasterTarget.classList.toggle("cursor-not-allowed", disabled)
    this.coffeeBagTarget.classList.toggle("cursor-not-allowed", disabled)
  }
}
