import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { post } from "@rails/request.js"

export default class extends Controller {
  static targets = ["dropArea", "loader", "error", "form", "files"]

  connect() {
    if (this.hasFilesTarget) {
      this.filesTarget.onchange = () => {
        this.dropAreaTarget.classList.add("hidden")
        this.loaderTarget.classList.remove("hidden")
        Turbo.navigator.submitForm(this.formTarget)
      }
    }

    this.dropAreaTarget.addEventListener("drop", this.handleDrop.bind(this))
  }

  disconnect() {
    if (this.hasFilesTarget) {
      this.filesTarget.onchange = null
    }
    this.dropAreaTarget.removeEventListener("drop", this.handleDrop.bind(this))
  }

  async handleDrop(e) {
    if (!e.dataTransfer.files.length) return

    this.dropAreaTarget.classList.add("hidden")
    this.loaderTarget.classList.remove("hidden")

    const formData = new FormData()
    ;[...e.dataTransfer.files].forEach(file => {
      formData.append("files[]", file)
    })

    try {
      const response = await post(this.formTarget.action + "?drag=1", {
        body: formData,
        responseKind: "turbo-stream"
      })

      if (response.ok) {
        Turbo.visit("/shots")
      } else {
        const notificationsContainer = document.getElementById("notifications-container")
        notificationsContainer.insertAdjacentHTML("beforeend", this.errorTarget.innerHTML)
      }
    } catch {
      const notificationsContainer = document.getElementById("notifications-container")
      notificationsContainer.insertAdjacentHTML("beforeend", this.errorTarget.innerHTML)
    } finally {
      this.loaderTarget.classList.add("hidden")
      this.dropAreaTarget.classList.remove("hidden")
    }
  }
}
