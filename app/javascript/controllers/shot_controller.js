import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  view(event) {
    let currentElement = event.target
    while (currentElement != event.currentTarget) {
      if (["A", "BUTTON"].includes(currentElement.tagName)) {
        return
      }
      currentElement = currentElement.parentElement
    }

    if (event.metaKey || event.ctrlKey) {
      window.open(event.currentTarget.dataset.url, "_blank")
    } else {
      Turbo.visit(event.currentTarget.dataset.url)
    }
  }
}
