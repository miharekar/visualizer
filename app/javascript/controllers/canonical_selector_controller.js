import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["autocomplete", "id", "roaster", "coffeeBag", "roasterWebsite", "verified", "input"]

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
    const selected = event.detail.selected
    const { roaster = "", coffeeBag = "", roasterWebsite = "" } = selected.dataset || {}

    if (this.hasRoasterTarget) this.roasterTarget.value = roaster
    if (this.hasCoffeeBagTarget) this.coffeeBagTarget.value = coffeeBag
    if (this.hasRoasterWebsiteTarget) this.roasterWebsiteTarget.value = roasterWebsite

    const raw_payload = selected.querySelector("[data-coffee-bag-payload-value]")?.dataset?.coffeeBagPayloadValue
    if (raw_payload) {
      const formEl = this.element.closest('form[data-controller~="coffee-bag-scraper"]')
      const scraper = formEl && this.application.getControllerForElementAndIdentifier(formEl, "coffee-bag-scraper")
      scraper?.populateFields(JSON.parse(raw_payload))
    }

    this.toggleInputs()
  }

  toggleInputs() {
    const hasIdValue = !!this.idTarget.value

    if (this.hasRoasterTarget) {
      this.roasterTarget.disabled = hasIdValue
      this.roasterTarget.classList.toggle("cursor-not-allowed", hasIdValue)
    }

    if (this.hasCoffeeBagTarget) {
      this.coffeeBagTarget.disabled = hasIdValue
      this.coffeeBagTarget.classList.toggle("cursor-not-allowed", hasIdValue)
    }

    if (this.hasVerifiedTarget) {
      if (hasIdValue) {
        this.verifiedTarget.classList.remove("hidden")
        this.inputTarget.classList.add("ps-10")
      } else {
        this.verifiedTarget.classList.add("hidden")
        this.inputTarget.classList.remove("ps-10")
      }
    }
  }
}
