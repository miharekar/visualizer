import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "icon"]

  connect() {
    this.showTab()
  }

  change(event) {
    event.preventDefault()
    this.index = this.tabTargets.indexOf(event.currentTarget)
  }

  showTab() {
    this.tabTargets.forEach((tab, index) => {
      const panel = this.panelTargets[index]
      const icon = this.iconTargets[index]

      if (index === this.index) {
        panel.classList.remove("hidden")
        tab.classList.add("active", "border-emerald-500", "text-emerald-600")
        tab.classList.remove("inactive", "border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        icon.classList.add("text-emerald-500")
        icon.classList.remove("text-gray-400", "group-hover:text-gray-500")
      } else {
        panel.classList.add("hidden")
        tab.classList.add("inactive", "border-transparent", "text-gray-500", "hover:text-gray-700", "hover:border-gray-300")
        tab.classList.remove("active", "border-emerald-500", "text-emerald-600")
        icon.classList.add("text-gray-400", "group-hover:text-gray-500")
        icon.classList.remove("text-emerald-500")
      }
    })
  }

  get index() {
    return parseInt(this.data.get("index") || 0)
  }

  set index(value) {
    this.data.set("index", (value >= 0 ? value : 0))
    this.showTab()
  }
}
