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
  }

  disconnect() {
    this.tagify.destroy()
  }
}
