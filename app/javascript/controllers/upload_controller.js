import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"
import { post } from "@rails/request.js"
import { appsignal } from "controllers/application"

const BATCH_SIZE = 50

export default class extends Controller {
  static targets = ["dropArea", "loader", "error", "form", "files"]

  connect() {
    if (this.hasFilesTarget) {
      this.filesTarget.onchange = () => this.upload(this.filesTarget.files)
    }

    this.dropAreaTarget.addEventListener("drop", this.handleDrop.bind(this))
  }

  disconnect() {
    if (this.hasFilesTarget) {
      this.filesTarget.onchange = null
    }
    this.dropAreaTarget.removeEventListener("drop", this.handleDrop.bind(this))
  }

  handleDrop(e) {
    this.upload(e.dataTransfer.files)
  }

  async upload(fileList) {
    const files = [...fileList]
    if (!files.length) return

    this.dropAreaTarget.classList.add("hidden")
    this.loaderTarget.classList.remove("hidden")

    try {
      for (let i = 0; i < files.length; i += BATCH_SIZE) {
        const formData = new FormData()
        files.slice(i, i + BATCH_SIZE).forEach(file => formData.append("files[]", file))

        const response = await post(this.formTarget.action + "?drag=1", {
          body: formData,
          responseKind: "turbo-stream"
        })
        if (response.unprocessableEntity) break
        if (!response.ok) return this.showError()
      }
      Turbo.visit("/shots")
    } catch (error) {
      appsignal.sendError(error)
      this.showError()
    } finally {
      this.loaderTarget.classList.add("hidden")
      this.dropAreaTarget.classList.remove("hidden")
    }
  }

  showError() {
    document.getElementById("notifications-container").insertAdjacentHTML("beforeend", this.errorTarget.innerHTML)
  }
}
