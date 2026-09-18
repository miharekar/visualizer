import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: JournalController } = await import("../../app/javascript/controllers/journal_controller.js")

function target() {
  const classes = new Set()
  return { textContent: "", classList: { add(name) { classes.add(name) }, remove(name) { classes.delete(name) }, toggle(name, on) { on ? classes.add(name) : classes.delete(name) }, contains(name) { return classes.has(name) } } }
}

function controller() {
  const controller = new JournalController()
  controller.connect()
  for (const name of ["draftError", "columnsError", "undoError", "undo", "undoLabel", "savedShot", "selection", "selectionNotice", "bulkBar", "searchNotice"]) controller[`${name}Target`] = target()
  controller.rowTargets = []
  controller.queryValue = {}
  controller.dialogTarget = { open: false }
  controller.restoreFailedValues = () => {}
  controller.resumeSearch = () => {}
  controller.rowsTarget = { querySelector: () => null }
  controller.hasUnsavedChanges = () => controller.busy || controller.queue.length > 0 || controller.failures.size > 0
  return controller
}

const settled = () => new Promise(resolve => setImmediate(resolve))

test("validation failure permits independent saves and correction clears failure", async () => {
  const journal = controller()
  const saved = []
  journal.enqueue(async () => { throw new Error("Enjoyment must be between 0 and 100") }, ["shot:enjoyment"])
  journal.enqueue(async () => { saved.push("dose") }, ["shot:dose"])
  await settled()
  assert.deepEqual(saved, ["dose"])
  assert.equal(journal.failures.size, 1)
  journal.enqueue(async () => { saved.push("enjoyment:90") }, ["shot:enjoyment"])
  await settled()
  assert.deepEqual(saved, ["dose", "enjoyment:90"])
  assert.equal(journal.failures.size, 0)
  assert.equal(journal.pending.size, 0)
})

test("correction supersedes only overlapping cells of a failed bulk operation", async () => {
  const journal = controller()
  let bulkAttempts = 0
  journal.enqueue(async () => { bulkAttempts++; throw new Error("Network unavailable") }, ["A:dose", "B:dose"])
  await settled()
  journal.enqueue(async () => {}, ["A:dose"])
  await settled()
  assert.equal(journal.failureForCell("A:dose"), undefined)
  assert(journal.failureForCell("B:dose"))
  journal.enqueue(async () => {}, ["B:dose"])
  await settled()
  assert.equal(journal.failures.size, 0)
  assert.equal(bulkAttempts, 1, "Old bulk values must never be replayed over corrections")
})

test("a failed value can be submitted again without changing its text", () => {
  const journal = controller()
  journal.failures.set("shot:dose", { keys: ["shot:dose"] })
  const cell = { dataset: { column: "dose" }, closest: () => ({ dataset: { shotId: "shot" } }) }
  const input = { value: "18", dataset: { original: "18" }, closest: () => cell }
  let saved
  journal.save = (ids, field, attributes) => { saved = { ids, field, attributes: attributes() } }
  journal.commit({ target: input })
  assert.deepEqual(saved, { ids: ["shot"], field: "dose", attributes: { dose: "18" } })
})

test("column saves are quiet and errors stay in columns panel", async () => {
  const journal = controller()
  journal.enqueue(async () => {}, [], "columns")
  await settled()
  assert.equal(journal.columnsErrorTarget.textContent, "")
  journal.enqueue(async () => { throw new Error("Network unavailable") }, [], "columns")
  await settled()
  assert.match(journal.columnsErrorTarget.textContent, /Couldn't save: Network unavailable/)
  assert.equal(journal.draftErrorTarget.textContent, "")
  assert.equal(journal.undoErrorTarget.textContent, "")
})

function stream(searchId, target = "journal-rows") {
  return { dataset: { journalSearchId: searchId, journalFreshSearch: "true" }, getAttribute: name => name === "target" ? target : "update" }
}

test("outdated search streams cannot change rows, counts, empty state or cursor", () => {
  const journal = controller()
  journal.searchIdValue = "new"
  for (const target of ["journal-rows", "shots-count", "journal-empty", "cursor"]) {
    let prevented = false
    journal.beforeStream({ target: stream("old", target), preventDefault() { prevented = true } })
    assert(prevented, target)
  }
})

test("search submitted before an edit is rejected even after edit finishes saving", () => {
  const journal = controller()
  journal.searchIdValue = "search"
  journal.searchEpoch = 0
  journal.editEpoch = 1
  journal.undoHistory.push({ token: "keep undo", ids: ["shot"] })
  let prevented = false
  journal.beforeStream({ target: stream("search"), preventDefault() { prevented = true } })
  assert(prevented)
  assert(journal.searchPending)
  assert.equal(journal.lastOperation.token, "keep undo")
})

test("search response does not remove a focused cell before it commits", () => {
  const journal = controller()
  journal.searchIdValue = "search"
  journal.rowsTarget.querySelector = () => ({ value: "typing" })
  let prevented = false
  journal.beforeStream({ target: stream("search"), preventDefault() { prevented = true } })
  assert(prevented)
})

test("accepted search keeps session undo available", () => {
  const journal = controller()
  journal.searchIdValue = "search"
  journal.pendingQuery = { q: "Gesha" }
  journal.undoHistory.push({ token: "keep undo", ids: ["shot"] })
  journal.tableViewportTarget = {}
  journal.tableTarget = { querySelector: () => ({ checked: true }) }
  journal.beforeStream({ target: stream("search"), preventDefault() { assert.fail("Search should be accepted") } })
  assert.equal(journal.lastOperation.token, "keep undo")
  assert.deepEqual(journal.queryValue, { q: "Gesha" })
})

test("Undo walks backwards through successful session changes", async () => {
  const journal = controller()
  journal.undoHistory.push({ token: "first", ids: ["shot"] }, { token: "second", ids: ["shot"] })
  const tokens = []
  journal.request = async (_url, _method, body) => { tokens.push(body.undo); return { rows: [] } }
  journal.renderRows = () => {}
  journal.undo()
  await settled()
  assert.equal(journal.lastOperation.token, "first")
  journal.undo()
  await settled()
  assert.deepEqual(tokens, ["second", "first"])
  assert.equal(journal.lastOperation, undefined)
  assert(journal.undoTarget.classList.contains("hidden!"))
})

test("undo shortcut preserves native editing and works from unchanged cells", () => {
  const journal = controller()
  journal.undoHistory.push({ token: "saved", ids: ["shot"] })
  let undos = 0
  journal.undo = () => { undos++ }
  const input = { value: "typing", dataset: { original: "original" } }
  const event = { key: "z", ctrlKey: true, target: { closest: () => input }, preventDefault() {} }
  journal.undoShortcut(event)
  assert.equal(undos, 0)
  input.value = "original"
  journal.undoShortcut(event)
  assert.equal(undos, 1)
  journal.undoShortcut({ ...event, ctrlKey: false, metaKey: true, target: { closest: selector => selector === "[data-editor]" ? null : {} } })
  assert.equal(undos, 1, "Rich text editors retain native undo")
  journal.undoShortcut({ ...event, ctrlKey: false, metaKey: true, target: { closest: () => null } })
  assert.equal(undos, 2)
})
