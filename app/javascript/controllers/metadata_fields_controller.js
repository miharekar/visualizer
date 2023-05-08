import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }
  static targets = ["input", "link"]

  add(event) {
    event.preventDefault()
    if (this.inputTarget.value === "") return
    this.linkTarget.href = `${this.urlValue}?field=${this.inputTarget.value}`
    this.linkTarget.click()
  }
}
