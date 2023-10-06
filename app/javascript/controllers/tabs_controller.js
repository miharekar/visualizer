import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "icon"]

  connect() {
    this.activeTabClasses = this.data.get("activeTab").split(" ")
    this.inactiveTabClasses = this.data.get("inactiveTab").split(" ")
    this.activeIconClasses = this.data.get("activeIcon").split(" ")
    this.inactiveIconClasses = this.data.get("inactiveIcon").split(" ")
  }

  change(event) {
    event.preventDefault()
    this.index = this.tabTargets.indexOf(event.currentTarget)
    document.cookie = "shots.selected_tab=" + (this.panelTargets[this.index].id || "") + "; path=/"
  }

  showTab() {
    this.tabTargets.forEach((tab, index) => {
      const panel = this.panelTargets[index]
      const icon = this.iconTargets[index]

      if (index === this.index) {
        panel.classList.remove("hidden")
        tab.classList.add(...this.activeTabClasses)
        tab.classList.remove(...this.inactiveTabClasses)
        icon.classList.add(...this.activeIconClasses)
        icon.classList.remove(...this.inactiveIconClasses)
      } else {
        panel.classList.add("hidden")
        tab.classList.add(...this.inactiveTabClasses)
        tab.classList.remove(...this.activeTabClasses)
        icon.classList.add(...this.inactiveIconClasses)
        icon.classList.remove(...this.activeIconClasses)
      }
    })
  }

  get index() {
    return parseInt(this.data.get("index") || 0)
  }

  set index(value) {
    this.data.set("index", value >= 0 ? value : 0)
    this.showTab()
  }
}
