import { Controller } from "stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  view(event) {
    if (["TR", "TD", "SPAN", "DIV"].includes(event.target.nodeName)) {
      event.preventDefault()
      Turbo.visit(event.currentTarget.dataset.url)
    }
  }
}
