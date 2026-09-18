import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

// Test the real save queue without Stimulus's browser wiring (Node 22.15+).
registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: JournalController } = await import("../../app/javascript/controllers/journal_controller.js")

function controller() {
  const controller = new JournalController()
  controller.connect()
  controller.statusTarget = {}
  controller.saveBarTarget = { classList: { add() {}, remove() {} } }
  controller.refreshStatus = () => {}
  controller.hasUnsavedChanges = () => controller.busy || controller.queue.length > 0 || controller.failures.size > 0
  return controller
}

const settled = () => new Promise(resolve => setImmediate(resolve))

test("validation failure permits other saves and correction replaces failed edit", async () => {
  const journal = controller()
  const saved = []
  journal.enqueue(async () => {
    throw new Error("Enjoyment must be between 0 and 100")
  }, ["shot:enjoyment"])
  journal.enqueue(async () => {
    saved.push("dose")
  }, ["shot:dose"])
  await settled()
  assert.deepEqual(saved, ["dose"])
  assert.equal(journal.failures.size, 1)
  assert.equal(journal.pending.size, 0)

  journal.enqueue(async () => {
    saved.push("enjoyment:90")
  }, ["shot:enjoyment"])
  await settled()
  assert.deepEqual(saved, ["dose", "enjoyment:90"])
  assert.equal(journal.failures.size, 0)
  assert.equal(journal.pending.size, 0)
})

test("failed requests can be retried without replaying successful saves", async () => {
  const journal = controller()
  let attempts = 0
  let otherSaves = 0
  journal.enqueue(async () => {
    if (++attempts === 1) throw new Error("Network unavailable")
  }, ["shot:notes"])
  journal.enqueue(async () => {
    otherSaves++
  }, ["shot:dose"])
  await settled()
  journal.retry()
  await settled()
  assert.equal(attempts, 2)
  assert.equal(otherSaves, 1)
  assert.equal(journal.failures.size, 0)
  assert.equal(journal.pending.size, 0)
})

test("column saves are quiet but failures remain visible", async () => {
  const journal = controller()
  const target = () => ({ classList: { toggle() {}, add() {}, remove() {} } })
  journal.saveBarTarget = target()
  journal.retryTarget = target()
  journal.reloadTarget = target()
  journal.rowsTarget = { querySelectorAll: () => [] }
  journal.refreshStatus = JournalController.prototype.refreshStatus.bind(journal)
  journal.enqueue(async () => {}, [], "columns")
  await settled()
  assert.equal(journal.statusTarget.textContent, "")
  journal.enqueue(
    async () => {
      throw new Error("Network unavailable")
    },
    [],
    "columns"
  )
  await settled()
  assert.match(journal.statusTarget.textContent, /Couldn't save: Network unavailable/)
})
