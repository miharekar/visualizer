import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["autocomplete", "id", "roaster", "coffeeBag", "roasterWebsite"]

  connect() {
    if (!this.hasIdTarget) return

    this.toggleInputs()
    this.autocompleteTarget.addEventListener("autocomplete.change", this.autocompleted.bind(this))
    this.observer = new MutationObserver(() => this.toggleInputs())
    this.observer.observe(this.idTarget, { attributes: true, attributeFilter: ["value"] })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  autocompleted(event) {
    const { roaster = "", coffeeBag = "", roasterWebsite = "" } = event.detail?.selected?.dataset || {}

    if (this.hasRoasterTarget) this.roasterTarget.value = roaster
    if (this.hasCoffeeBagTarget) this.coffeeBagTarget.value = coffeeBag
    if (this.hasRoasterWebsiteTarget) this.roasterWebsiteTarget.value = roasterWebsite

    this.toggleInputs()
  }

  toggleInputs() {
    const disabled = !!this.idTarget?.value

    if (this.hasRoasterTarget) {
      this.roasterTarget.disabled = disabled
      this.roasterTarget.classList.toggle("cursor-not-allowed", disabled)
    }

    if (this.hasCoffeeBagTarget) {
      this.coffeeBagTarget.disabled = disabled
      this.coffeeBagTarget.classList.toggle("cursor-not-allowed", disabled)
    }
  }
}
