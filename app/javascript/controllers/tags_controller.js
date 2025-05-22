import { Controller } from "@hotwired/stimulus"
import Tagify from "@yaireo/tagify"

export default class extends Controller {
  static targets = ["input"]
  static values = { userTags: Array }

  connect() {
    this.tagify = new Tagify(this.inputTarget, {
      whitelist: this.userTagsValue,
      dropdown: {
        enabled: 0,
        closeOnSelect: false
      },
      originalInputValueFormat: valuesArr => valuesArr.map(item => item.value).join(",")
    })
  }
}
