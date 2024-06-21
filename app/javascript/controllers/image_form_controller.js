import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["label"]

  update(event) {
    if (event.currentTarget.files.length > 0) {
      this.labelTarget.innerHTML = event.currentTarget.files[0].name
    }
  }
}
