import { Controller } from "stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  compare(event) {
    const select = event.currentTarget
    const shot = select.dataset.shotId
    const compare = select.value

    Turbo.visit("/shots/" + shot + "/compare/" + compare)
  }
}
