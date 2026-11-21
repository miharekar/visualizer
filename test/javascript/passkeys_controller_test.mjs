import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { afterEach, test } from "node:test"

globalThis.reportedErrors = []

registerHooks({
  resolve(specifier, context, next) {
    const stubs = {
      "@hotwired/stimulus": "export class Controller {}",
      "controllers/application": "export const appsignal = { sendError: error => globalThis.reportedErrors.push(error) }"
    }
    if (Object.hasOwn(stubs, specifier)) return { url: `data:text/javascript,${encodeURIComponent(stubs[specifier])}`, shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: Passkeys } = await import("../../app/javascript/controllers/passkeys_controller.js")

const originalNavigator = Object.getOwnPropertyDescriptor(globalThis, "navigator")
const originalConsoleError = console.error

afterEach(() => {
  Object.defineProperty(globalThis, "navigator", originalNavigator)
  delete globalThis.PublicKeyCredential
  console.error = originalConsoleError
  globalThis.reportedErrors.length = 0
})

function passkeys(error) {
  const reject = () => Promise.reject(error)
  globalThis.PublicKeyCredential = { parseCreationOptionsFromJSON: opts => opts, parseRequestOptionsFromJSON: opts => opts }
  Object.defineProperty(globalThis, "navigator", { value: { credentials: { create: reject, get: reject } }, configurable: true })
  console.error = () => {}

  const controller = new Passkeys()
  controller.notifications = []
  controller.postJSON = async () => ({})
  controller.showNotification = id => controller.notifications.push(id)
  return controller
}

const credentialManagerError = () => new DOMException("An unknown error occurred while talking to the credential manager.", "NotReadableError")

test("register shows an error without reporting credential manager failures", async () => {
  const controller = passkeys(credentialManagerError())

  await controller.register()

  assert.deepEqual(controller.notifications, ["passkey-error"])
  assert.deepEqual(globalThis.reportedErrors, [])
})

test("sign in shows an error without reporting credential manager failures", async () => {
  const controller = passkeys(credentialManagerError())

  await controller.buttonSignIn()

  assert.deepEqual(controller.notifications, ["passkey-error"])
  assert.deepEqual(globalThis.reportedErrors, [])
})

test("unexpected errors are still reported", async () => {
  const error = new Error("boom")
  const controller = passkeys(error)

  await controller.register()

  assert.deepEqual(controller.notifications, ["passkey-error"])
  assert.deepEqual(globalThis.reportedErrors, [error])
})
