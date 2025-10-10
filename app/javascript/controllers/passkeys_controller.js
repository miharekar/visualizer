import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autologin: Boolean }

  async connect() {
    if (this.autologinValue && (await this.conditionalAvailable())) {
      try {
        await this.signIn()
      } catch {}
    }
  }

  async register(e) {
    e.preventDefault()
    const opts = await this.postJSON("/passkeys/options", {})
    const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(opts)
    const cred = await navigator.credentials.create({ publicKey })
    if (!cred) return

    const nickname = prompt("Name this passkey", "Passkey")
    await this.postJSON("/passkeys", this.buildPayload(cred, { nickname }))

    const c = document.getElementById("notifications-container")
    const tpl = document.getElementById("passkey-success")
    c.insertAdjacentHTML("beforeend", tpl.innerHTML)
  }

  async signIn() {
    const opts = await this.postJSON("/passkeys/sign_in", {})
    const publicKey = PublicKeyCredential.parseRequestOptionsFromJSON(opts)
    const cred = await navigator.credentials.get({ publicKey, mediation: "conditional" })
    if (!cred) return

    try {
      const res = await this.postJSON("/passkeys/callback", this.buildPayload(cred))
      if (res?.redirect_to) window.location.href = res.redirect_to
    } catch {
      const c = document.getElementById("notifications-container")
      const tpl = document.getElementById("passkey-error")
      c.insertAdjacentHTML("beforeend", tpl.innerHTML)
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
    const data = await res.json().catch(() => ({}))
    if (!res.ok) throw new Error(data.error || res.statusText)
    return data
  }
}
