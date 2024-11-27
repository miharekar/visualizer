import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["url", "loader"]

  async fetch() {
    const url = this.urlTarget.value
    if (!url) return

    try {
      this.loaderTarget.classList.remove("hidden")

      this.element.querySelectorAll('input, select, textarea, button').forEach(el => {
        el.disabled = true
        el.classList.add("opacity-50", "cursor-wait")
      })

      const response = await fetch(this.urlTarget.dataset.scrapeUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ url })
      })

      if (!response.ok) throw new Error('Failed to fetch coffee info')

      const data = await response.json()
      this.populateFields(data)
    } catch (error) {
      console.error('Error fetching coffee info:', error)
    } finally {
      this.loaderTarget.classList.add("hidden")

      this.element.querySelectorAll('input, select, textarea, button').forEach(el => {
        el.disabled = false
        el.classList.remove("opacity-50", "cursor-wait")
      })
    }
  }

  populateFields(data) {
    const fields = [
      'name', 'roast_level', 'country', 'region', 'farm', 'farmer', 'variety', 'elevation', 'processing', 'harvest_time', 'quality_score'
    ]

    fields.forEach(field => {
      const input = document.querySelector(`#coffee_bag_${field}`)
      if (input && data[field]) {
        input.value = data[field]
      }
    })
  }
}