import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "status"]

  async register(e) {
    e.preventDefault()
    const opts = await this.postJSON("/passkeys/options", {})
    const publicKey = PublicKeyCredential.parseCreationOptionsFromJSON(opts)
    const cred = await navigator.credentials.create({ publicKey })
    if (!cred) return

    const nickname = prompt("Name this passkey", "Passkey")
    await this.postJSON("/passkeys", this.attestationPayload(cred, nickname))

    const notificationsContainer = document.getElementById("notifications-container")
    const successNotification = document.getElementById("passkey-success")
    notificationsContainer.insertAdjacentHTML("beforeend", successNotification.innerHTML)
  }

  attestationPayload(cred, nickname) {
    return {
      id: cred.id,
      rawId: this.b64url(cred.rawId),
      type: cred.type,
      authenticatorAttachment: cred.authenticatorAttachment ?? undefined,
      clientExtensionResults: cred.getClientExtensionResults?.() ?? {},
      response: {
        attestationObject: this.b64url(cred.response.attestationObject),
        clientDataJSON: this.b64url(cred.response.clientDataJSON),
        transports: cred.response.getTransports?.() ?? undefined
      },
      nickname
    }
  }

  b64url(buf) {
    const b = String.fromCharCode(...new Uint8Array(buf))
    return btoa(b).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")
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
