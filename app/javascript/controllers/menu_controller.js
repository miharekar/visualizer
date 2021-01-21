
import { Controller } from "stimulus"
// import the enter leave functions
import { enter, leave } from "el-transition";

export default class extends Controller {
  static targets = ["toggleable", "transformable", "button"]

  initialize() {
    this.menuShown = false
  }

  toggle() {
    this.toggleableTargets.forEach((element) => {
      element.classList.toggle("hidden")
    })
  }

  transform() {
    if (this.menuShown) {
      enter(this.transformableTarget)
    } else {
      leave(this.transformableTarget)
    }
    this.menuShown = !menuClassList.contains("hidden")
  }

  hide(event) {
    const buttonClicked = this.buttonTarget.contains(event.target)

    if (!buttonClicked && this.menuShown) {
      this.transform(this.transformableTarget)
    }
  }
}
