import { Controller } from "stimulus"

export default class extends Controller {
  static targets = ["label"]

  update(event) {
    if (event.currentTarget.files.length > 0) {
      this.labelTarget.innerHTML = event.currentTarget.files[0].name
    }
  }
}
