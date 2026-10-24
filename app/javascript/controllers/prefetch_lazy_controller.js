import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (this.element.getAttribute("loading") == "lazy") {
      const margin = "0px 0px 1000px 0px"
      const options = "scrollMargin" in IntersectionObserver.prototype ? { scrollMargin: margin } : { rootMargin: margin }
      this.observer = new IntersectionObserver(this.intersect.bind(this), options)
      this.observer.observe(this.element)
    }
  }

  disconnect() {
    this.observer?.disconnect()
  }

  intersect(entries) {
    const lastEntry = entries.slice(-1)[0]
    if (lastEntry?.isIntersecting) {
      this.observer.unobserve(this.element) // We only need to do this once
      this.element.setAttribute("loading", "eager")
    }
  }
}
