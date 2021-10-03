import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

const uuidV4Regex = /shots\/([A-F\d]{8}-[A-F\d]{4}-4[A-F\d]{3}-[89AB][A-F\d]{3}-[A-F\d]{12}$)/i;

export default class extends Controller {
  static values = { shotId: String }

  compare(event) {
    const select = event.currentTarget
    const compare = select.value
    Turbo.visit("/shots/" + this.shotIdValue + "/compare/" + compare)
  }

  url(event) {
    const input = event.currentTarget
    const url = input.value
    const uuidMatch = url.match(uuidV4Regex)

    if (uuidMatch) {
      input.value = ""
      input.placeholder = "With any shot via its URL"
      input.classList.remove("focus:placeholder-red-500", "focus:ring-red-500", "focus:border-red-500")
      Turbo.visit("/shots/" + this.shotIdValue + "/compare/" + uuidMatch.pop())
    } else {
      input.value = ""
      input.placeholder = "Please enter a valid shot URL"
      input.classList.add("focus:placeholder-red-500", "focus:ring-red-500", "focus:border-red-500")
    }
  }
}
