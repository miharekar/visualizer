import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "display", "data"]

  connect() {
    this.renderTags()
  }

  inputTag(event) {
    if (event.shiftKey || event.ctrlKey || event.metaKey || event.altKey) {
      return
    }

    if (event.code === "Enter" || event.code === "Comma") {
      event.preventDefault()
      const value = this.inputTarget.value.trim().replace(/[^\w\s-]/g, "")

      if (value) {
        this.tags = value
        this.inputTarget.value = ""
        this.renderTags()
      }
    }
  }

  removeTag(event) {
    event.preventDefault()
    const tagElement = event.currentTarget.parentElement
    const tagText = tagElement.querySelector('span').textContent.trim()

    if (tagText) {
      const tags = this.tags
      const tagIndex = tags.indexOf(tagText)
      if (tagIndex !== -1) {
        tags.splice(tagIndex, 1)
        this.dataTarget.value = tags
        this.renderTags()
      }
    }
  }

  renderTags() {
    this.displayTarget.innerHTML = ""
    const sortedTags = [...this.tags].sort((a, b) => a.localeCompare(b))
    sortedTags.forEach(tag => {
      this.displayTarget.insertAdjacentHTML('beforeend', this.tagTemplate(tag))
    })
  }

  tagTemplate(tag) {
    return `
      <span class="inline-flex items-center gap-x-0.5 rounded-md bg-oxford-blue-50 px-2 py-1 text-xs font-medium text-oxford-blue-600">
        <span>${tag}</span>
        <button type="button" class="group relative -mr-1 size-3.5 rounded-xs hover:bg-oxford-blue-500/20" data-action="click->tags#removeTag">
          <span class="sr-only">Remove</span>
          <svg viewBox="0 0 14 14" class="size-3.5 stroke-oxford-blue-600/50 group-hover:stroke-oxford-blue-600/75">
            <path d="M4 4l6 6m0-6l-6 6" />
          </svg>
          <span class="absolute -inset-1"></span>
        </button>
      </span>
    `
  }

  set tags(value) {
    const tag = value.trim().replace(/,/g, "").toLowerCase()
    const tags = this.tags
    if (tags.indexOf(tag) === -1 && tag !== "") {
      tags.push(tag)
      this.dataTarget.value = tags
    }
  }

  get tags() {
    return this.dataTarget.value.split(",").filter(tag => tag.length > 0)
  }
}
