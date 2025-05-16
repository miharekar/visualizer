import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static minY = 64

  connect() {
    this.scrollHandler = this.handleScroll.bind(this)
    window.addEventListener("scroll", this.scrollHandler)
    document.addEventListener("turbo:load", this.scrollHandler)
  }

  disconnect() {
    window.removeEventListener("scroll", this.scrollHandler)
    document.removeEventListener("turbo:load", this.scrollHandler)
  }

  handleScroll() {
    const scrollY = window.scrollY
    const notification = this.element

    notification.classList.remove("sm:top-16")

    if (scrollY < this.constructor.minY) {
      notification.style.top = `${this.constructor.minY - scrollY}px`
      notification.classList.remove("sm:top-4")
    } else {
      notification.style.top = "0px"
      notification.classList.add("sm:top-4")
    }
  }
}
