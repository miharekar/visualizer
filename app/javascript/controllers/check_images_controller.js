import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  initialize() {
    this.hasImages = false
  }

  containerTargetConnected() {
    if (!this.hasImages) this.checkIfContainersHaveImages()
    if (this.hasImages) this.showContainers()
  }

  checkIfContainersHaveImages() {
    this.hasImages = this.containerTargets.some(container => container.querySelector("img"))
  }

  showContainers() {
    this.containerTargets.forEach(container => container.classList.add("sm:block"))
  }
}
