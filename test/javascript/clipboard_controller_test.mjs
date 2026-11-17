import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { mock, test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: `data:text/javascript,${encodeURIComponent("export class Controller {}")}`, shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: Clipboard } = await import("../../app/javascript/controllers/clipboard_controller.js")

async function copy(clipboard, clicks = click => click()) {
  mock.timers.enable({ apis: ["setTimeout"] })
  const inserted = []
  const templates = { "clipboard-success": { innerHTML: "success" }, "clipboard-error": { innerHTML: "error" } }
  const classes = () => {
    const list = new Set()
    return {
      list,
      add: (...names) => names.forEach(name => list.add(name)),
      remove: (...names) => names.forEach(name => list.delete(name))
    }
  }
  const check = classes()
  const original = Object.getOwnPropertyDescriptor(globalThis, "navigator")
  globalThis.document = { getElementById: id => id === "notifications-container" ? { insertAdjacentHTML: (_, html) => inserted.push(html) } : templates[id] }
  Object.defineProperty(globalThis, "navigator", { value: { clipboard }, configurable: true })
  check.add("hidden")
  const controller = Object.assign(new Clipboard(), {
    sourceTarget: { value: "https://example.com/shots/1" },
    copyTarget: { classList: classes() },
    checkTarget: { classList: check },
    containerTarget: { classList: classes() }
  })
  try {
    await clicks(() => controller.copy({ preventDefault() {} }))
  } finally {
    Object.defineProperty(globalThis, "navigator", original)
    delete globalThis.document
    mock.timers.reset()
  }
  return { inserted, checkShown: !check.list.has("hidden") }
}

test("shows the success toast and check icon after the write resolves", async () => {
  const written = []
  const result = await copy({ writeText: async text => written.push(text) })
  assert.deepEqual(written, ["https://example.com/shots/1"])
  assert.deepEqual(result, { inserted: ["success"], checkShown: true })
})

test("ignores repeat clicks until the copied state resets", async () => {
  const written = []
  const result = await copy({ writeText: async text => written.push(text) }, async click => {
    await Promise.all([click(), click()])
    await click()
    mock.timers.tick(2000)
    await click()
  })
  assert.equal(written.length, 2)
  assert.deepEqual(result, { inserted: ["success", "success"], checkShown: true })
})

test("shows the error toast and no check icon each time the write rejects", async () => {
  const writeText = async () => {
    throw new DOMException("denied", "NotAllowedError")
  }
  const result = await copy({ writeText }, async click => {
    await click()
    await click()
  })
  assert.deepEqual(result, { inserted: ["error", "error"], checkShown: false })
})

test("shows the error toast when navigator.clipboard is missing", async () => {
  assert.deepEqual(await copy(undefined), { inserted: ["error"], checkShown: false })
})
