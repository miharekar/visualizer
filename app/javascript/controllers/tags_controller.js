import { Controller } from "@hotwired/stimulus"
import Tagify from "@yaireo/tagify"

export default class extends Controller {
  static targets = ["input"]
  static values = {
    enforceWhitelist: { type: Boolean, default: false },
    tagTextProp: { type: String, default: "value" },
    userTags: Array
  }

  connect() {
    this.tagify = new Tagify(this.inputTarget, {
      enforceWhitelist: this.enforceWhitelistValue,
      tagTextProp: this.tagTextPropValue,
      whitelist: this.userTagsValue,
      dropdown: {
        enabled: 0,
        closeOnSelect: false,
        searchKeys: ["search", "name", "value"]
      },
      originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(",")
    })
    if (this.inputTarget.closest("dialog")) {
      this.tagify.settings.dropdown.appendTarget = this.tagify.DOM.scope
      this.tagify.settings.dropdown.closeOnSelect = true
      const position = this.tagify.dropdown.position
      this.tagify.dropdown.position = height => {
        position(height)
        // The dropdown is local to the dialog, not offset by document scrolling.
        const dropdown = this.tagify.DOM.dropdown
        dropdown.style.left = "-1px"
        dropdown.style.top = dropdown.getAttribute("placement") === "top" ? "-1px" : `${this.tagify.DOM.scope.offsetHeight - 1}px`
      }
    }
  }

  disconnect() {
    this.tagify.destroy()
  }
}
