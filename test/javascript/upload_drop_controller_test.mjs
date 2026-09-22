import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: UploadDrop } = await import("../../app/javascript/controllers/upload_drop_controller.js")

test("only file drags activate uploads, and disconnect removes document listeners", () => {
  globalThis.document = new EventTarget()
  const controller = new UploadDrop()
  controller.initialize()
  const classes = new Set(["hidden"])
  controller.overlayTarget = Object.assign(new EventTarget(), {
    classList: { add: value => classes.add(value), remove: value => classes.delete(value) }
  })
  let uploads = 0
  controller.uploadOutlet = { handleDrop: () => uploads++ }
  const drag = (type, types) => Object.assign(new Event(type, { cancelable: true }), { dataTransfer: { types } })
  controller.connect()
  const column = drag("dragenter", ["text/plain"])
  document.dispatchEvent(column)
  assert.equal(column.defaultPrevented, false)
  assert.ok(classes.has("hidden"))
  const file = drag("dragenter", ["Files"])
  document.dispatchEvent(file)
  assert.equal(file.defaultPrevented, true)
  assert.ok(classes.has("flex"))
  controller.overlayTarget.dispatchEvent(drag("drop", ["Files"]))
  assert.equal(uploads, 1)
  assert.ok(classes.has("hidden"))
  controller.disconnect()
  const disconnected = drag("dragenter", ["Files"])
  document.dispatchEvent(disconnected)
  assert.equal(disconnected.defaultPrevented, false)
  assert.ok(classes.has("hidden"))
  delete globalThis.document
})
