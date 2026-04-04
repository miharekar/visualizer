import { Controller } from "@hotwired/stimulus"
import { appsignal } from "controllers/application"

export default class extends Controller {
  static values = { autologin: Boolean }

  async connect() {
    if (this.autologinValue && (await this.conditionalAvailable())) {
      await this.signIn({ mediation: "conditional" })
    }
  }

  async register() {
    if (typeof PublicKeyCredential?.parseCreationOptionsFromJSON !== "function") return

    try {
      const opts = await this.postJSON("/passkeys/options", {})
      const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(opts)
      const cred = await navigator.credentials.create({ publicKey })
      if (!cred) return

      const nickname = prompt("Name this passkey", "Passkey")
      await this.postJSON("/passkeys", this.buildPayload(cred, { nickname }))

      this.showNotification("passkey-success")
    } catch (error) {
      if (this.duplicateRegistrationError(error)) return this.showNotification("passkey-already-registered")
      if (this.expectedWebAuthnError(error)) return
      appsignal.sendError(error)
      console.error("Passkey registration failed", error)
      this.showNotification("passkey-error")
    }
  }

  async buttonSignIn() {
    await this.signIn({ mediation: "required" })
  }

  async signIn({ mediation }) {
    if (typeof PublicKeyCredential?.parseRequestOptionsFromJSON !== "function") return

    try {
      const opts = await this.postJSON("/passkeys/sign_in", {})
      const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(opts)

      if (this.getAbortController) this.getAbortController.abort()
      this.getAbortController = new AbortController()

      const cred = await navigator.credentials.get({
        publicKey,
        mediation,
        signal: this.getAbortController.signal
      })

      if (!cred) return

      const res = await this.postJSON("/passkeys/callback", this.buildPayload(cred))
      if (res?.redirect_to) window.location.href = res.redirect_to
    } catch (error) {
      if (this.expectedWebAuthnError(error)) return

      appsignal.sendError(error)
      console.error("Passkey sign-in failed", error)
      this.showNotification("passkey-error")
    }
  }

  buildPayload(cred, extra = {}) {
    return {
      id: cred.id,
      rawId: this.b64url(cred.rawId),
      type: cred.type,
      authenticatorAttachment: cred.authenticatorAttachment ?? undefined,
      clientExtensionResults: cred.getClientExtensionResults?.() ?? {},
      response: this.responseFields(cred),
      ...extra
    }
  }

  responseFields(cred) {
    const r = cred.response
    if ("attestationObject" in r) {
      return {
        attestationObject: this.b64url(r.attestationObject),
        clientDataJSON: this.b64url(r.clientDataJSON),
        transports: r.getTransports?.() ?? undefined
      }
    } else if ("authenticatorData" in r) {
      return {
        authenticatorData: this.b64url(r.authenticatorData),
        clientDataJSON: this.b64url(r.clientDataJSON),
        signature: this.b64url(r.signature),
        userHandle: r.userHandle ? this.b64url(r.userHandle) : null
      }
    }
  }

  b64url(buf) {
    const b = String.fromCharCode(...new Uint8Array(buf))
    return btoa(b).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
  }

  async conditionalAvailable() {
    try {
      return !!(PublicKeyCredential.isConditionalMediationAvailable && (await PublicKeyCredential.isConditionalMediationAvailable()))
    } catch {
      return false
    }
  }

  expectedWebAuthnError(error) {
    return error?.name === "AbortError" || error?.name === "NotAllowedError"
  }

  duplicateRegistrationError(error) {
    return error?.name === "InvalidStateError"
  }

  async postJSON(url, body) {
    const res = await fetch(url, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
      },
      body: JSON.stringify(body)
    })

    const text = await res.text()
    const data = text ? JSON.parse(text) : {}

    if (!res.ok) {
      const error = new Error(text)
      error.status = res.status
      error.data = data
      throw error
    }

    return data
  }

  showNotification(templateId) {
    const container = document.getElementById("notifications-container")
    const template = document.getElementById(templateId)
    if (container && template) container.insertAdjacentHTML("beforeend", template.innerHTML)
  }
}
