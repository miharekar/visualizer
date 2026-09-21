import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["search", "results", "error"]

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
    } else if (!this.discardUnsavedChanges()) {
      event.preventDefault()
    } else {
      this.loading = true
      this.resultsTarget.inert = true
    }
  }

  apply(event) {
    if (this.loading || this.resultsTarget.querySelector("[data-saving]")) {
      event.preventDefault()
      this.errorTarget.textContent = "Wait for pending saves or search to finish, then Apply."
    } else if (!this.discardUnsavedChanges()) {
      event.preventDefault()
    } else {
      const query = new FormData(this.searchTarget)
      for (const input of event.target.querySelectorAll("[data-journal-filter]")) input.value = query.get(input.dataset.journalFilter) || ""
      this.loading = true
      this.resultsTarget.inert = true
    }
  }

  discardUnsavedChanges() {
    return !this.resultsTarget.querySelector("[data-unsaved]") || confirm("Discard unsaved changes?")
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
