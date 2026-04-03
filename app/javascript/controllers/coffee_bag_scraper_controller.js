import { Controller } from "@hotwired/stimulus"
import consumer from "channels/consumer"

const LOADING_CLASSES = ["opacity-50", "cursor-wait"]
const STEP_ORDER = ["starting", "fetching", "retrying", "extracting", "finalizing"]
const PROGRESS_WIDTHS = { starting: 10, fetching: 35, retrying: 50, extracting: 75, finalizing: 90 }
const STEP_CLASSES = { idle: ["text-neutral-500", "dark:text-neutral-400"], active: ["text-terracotta-600", "dark:text-terracotta-400"], complete: ["line-through", "text-neutral-400", "dark:text-neutral-500"] }
const FORM_ELEMENT_SELECTOR = "input, select, textarea, button"

export default class extends Controller {
  static targets = ["progress", "progressBar", "url"]

  connect() {
    this.currentRequestId = null
    this.didRetry = false
    this.hideProgressTimeout = null
    this.formElements = [...this.element.querySelectorAll(FORM_ELEMENT_SELECTOR)]
    this.stepElements = [...this.progressTarget.querySelectorAll("[data-step]")]
    this.resetSubscriptionReady()
    this.createSubscription()
  }

  disconnect() {
    this.clearProgressTimeout()
    this.subscription?.unsubscribe()
  }

  async fetch(event) {
    if (event.type === "click") event.preventDefault()

    const url = this.urlTarget.value
    if (!url) return

    this.currentRequestId = this.requestId()
    this.didRetry = false
    this.setLoading(true)
    this.showProgress("starting")

    try {
      await Promise.race([this.subscriptionReady, new Promise(resolve => window.setTimeout(resolve, 1000))])
      await this.createScrapeRequest(url)
    } catch (error) {
      this.fail(error.message)
    }
  }

  received(payload) {
    if (payload.request_id !== this.currentRequestId) return

    if (payload.status) {
      this.showProgress(payload.status)
      return
    }

    if (payload.error) {
      this.fail(payload.error)
      return
    }

    this.setLoading(false)
    this.dispatchApply(payload.data)
    this.completeProgress()
    this.currentRequestId = null
  }

  setLoading(isLoading) {
    this.formElements.forEach(element => {
      element.disabled = isLoading
      this.toggleClasses(element, LOADING_CLASSES, isLoading)
    })
  }

  showError(message) {
    const template = document.getElementById("scraper-error-template")
    const notificationHtml = template.innerHTML
    const updatedNotification = notificationHtml.replace("Something went wrong", message)

    const notificationsContainer = document.getElementById("notifications-container")
    notificationsContainer.insertAdjacentHTML("beforeend", updatedNotification)
  }

  showProgress(step) {
    if (step === "retrying") this.didRetry = true

    this.clearProgressTimeout()
    this.progressTarget.classList.remove("hidden")
    this.progressBarTarget.style.width = `${PROGRESS_WIDTHS[step] || 0}%`
    this.stepElements.forEach(element => this.renderStep(element, step))
  }

  resetProgress() {
    this.clearProgressTimeout()
    this.didRetry = false
    this.progressTarget.classList.add("hidden")
    this.progressBarTarget.style.width = "0%"
    this.stepElements.forEach(element => this.setStepState(element, "idle"))
  }

  completeProgress() {
    this.showProgress("finalizing")
    this.progressBarTarget.style.width = "100%"
    this.stepElements.forEach(element => this.setStepState(element, "complete"))
    this.hideProgressTimeout = window.setTimeout(() => this.resetProgress(), 300)
  }

  requestId() {
    if (window.crypto?.randomUUID) return window.crypto.randomUUID()
    return `${Date.now()}-${Math.random().toString(16).slice(2)}`
  }

  async createScrapeRequest(url) {
    const response = await fetch(this.urlTarget.dataset.scrapeUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ url, request_id: this.currentRequestId })
    })
    if (response.ok) return

    const data = await response.json()
    throw new Error(data.error || "Failed to fetch coffee info")
  }

  fail(message) {
    this.setLoading(false)
    this.currentRequestId = null
    this.resetProgress()
    this.showError(message)
  }

  createSubscription() {
    this.subscription = consumer.subscriptions.create(
      { channel: "CoffeeBagScraperChannel" },
      {
        connected: () => this.resolveSubscriptionReady(),
        disconnected: () => this.resetSubscriptionReady(),
        received: payload => this.received(payload)
      }
    )
  }

  resetSubscriptionReady() {
    this.subscriptionReady = new Promise(resolve => {
      this.resolveSubscriptionReady = resolve
    })
  }

  renderStep(element, currentStep) {
    const step = element.dataset.step
    const currentIndex = STEP_ORDER.indexOf(currentStep)
    const stepIndex = STEP_ORDER.indexOf(step)

    element.classList.toggle("hidden", step === "retrying" && !this.didRetry)
    if (stepIndex < currentIndex) this.setStepState(element, "complete")
    if (stepIndex === currentIndex) this.setStepState(element, "active")
    if (stepIndex > currentIndex) this.setStepState(element, "idle")
  }

  setStepState(element, state) {
    const label = element.querySelector("[data-step-label]")
    this.toggleClasses(element, STEP_CLASSES.idle, state === "idle")
    this.toggleClasses(element, STEP_CLASSES.active, state === "active")
    this.toggleClasses(element, STEP_CLASSES.complete, state === "complete")
    label.classList.toggle("line-through", state === "complete")
  }

  toggleClasses(element, classes, enabled) {
    classes.forEach(className => element.classList.toggle(className, enabled))
  }

  dispatchApply(data) {
    this.element.dispatchEvent(new CustomEvent("coffee-bag:apply", { detail: { data, clearCanonicalId: true } }))
  }

  clearProgressTimeout() {
    if (!this.hideProgressTimeout) return

    window.clearTimeout(this.hideProgressTimeout)
    this.hideProgressTimeout = null
  }
}
