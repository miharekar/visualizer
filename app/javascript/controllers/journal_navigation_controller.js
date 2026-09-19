import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "results"]

  connect() {
    this.observer = new MutationObserver(() => this.resume())
    this.observer.observe(this.resultsTarget, { childList: true, subtree: true, attributes: true, attributeFilter: ["data-saving"] })
  }

  disconnect() {
    this.observer.disconnect()
  }

  search(event) {
    if (this.loading || this.resultsTarget.querySelector("[data-saving]")) {
      event.preventDefault()
      this.waiting = true
    } else if (this.resultsTarget.querySelector("[data-unsaved]") && !confirm("Discard unsaved changes and search?")) {
      event.preventDefault()
    } else {
      this.loading = true
      this.resultsTarget.inert = true
    }
  }

  resume() {
    if (!this.waiting || this.loading || this.resultsTarget.querySelector("[data-saving]")) return
    this.waiting = false
    this.searchTarget.requestSubmit()
  }

  loaded(event) {
    if (event.target !== this.resultsTarget) return
    this.loading = false
    this.resultsTarget.inert = false
    this.resume()
  }

  complete(event) {
    if (event.detail.success) return
    this.loading = false
    this.resultsTarget.inert = false
    this.resume()
  }
}
