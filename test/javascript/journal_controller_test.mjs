import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: Cell } = await import("../../app/javascript/controllers/journal_cell_controller.js")
const { default: Selection } = await import("../../app/javascript/controllers/journal_selection_controller.js")
const { default: Columns } = await import("../../app/javascript/controllers/journal_columns_controller.js")

test("cell changes submit ordinary forms; Enter navigates without duplicate submission", () => {
  const cell = new Cell()
  let submissions = 0
  let focused = 0
  let blurred = 0
  const control = { focus: () => focused++, select() {} }
  const neighbor = { querySelector: () => control }
  const row = { previousElementSibling: neighbor, nextElementSibling: neighbor }
  cell.element = { reportValidity: () => true, requestSubmit: () => submissions++, closest: () => ({ dataset: { column: "dose" }, closest: () => row }) }
  cell.inputTarget = {}
  cell.errorTarget = {}
  globalThis.CSS = { escape: value => value }
  cell.submit()
  for (const shiftKey of [false, true]) cell.navigate({ key: "Enter", shiftKey, preventDefault() {}, target: { blur: () => blurred++ } })
  cell.navigate({ key: "Enter", isComposing: true })
  assert.equal(submissions, 1)
  assert.equal(focused, 2)
  assert.equal(blurred, 2)
  assert.equal(cell.inputTarget.readOnly, true)
  cell.complete({ detail: { success: false } })
  assert.equal(cell.inputTarget.readOnly, false)
  assert.match(cell.errorTarget.textContent, /Press Enter to retry/)
  cell.navigate({ key: "Enter", preventDefault() {}, target: { blur() {} } })
  assert.equal(submissions, 2)
})

test("selection caps at 100, builds compare link, and resets after server marker replacement", () => {
  const selection = new Selection()
  const target = () => ({ classList: { toggle() {} } })
  selection.hasCountTarget = selection.hasAllTarget = true
  selection.checkboxTargets = Array.from({ length: 105 }, (_, index) => ({ value: `shot-${index}`, checked: false }))
  for (const name of ["count", "notice", "toolbar", "compare", "all"]) selection[`${name}Target`] = target()
  selection.selectAll({ target: { checked: true } })
  assert.equal(selection.selected.length, 100)
  assert.equal(selection.allTarget.indeterminate, true)
  selection.checkboxTargets[100].checked = true
  selection.select({ target: selection.checkboxTargets[100] })
  assert.equal(selection.selected.length, 100)
  selection.resetTargetConnected()
  assert.equal(selection.selected.length, 0)
  selection.checkboxTargets[0].checked = selection.checkboxTargets[1].checked = true
  selection.select()
  assert.equal(selection.compareTarget.href, "/shots/shot-0/compare/shot-1")
  selection.checkboxTargets.splice(1, 1)
  selection.checkboxTargetDisconnected()
  assert.equal(selection.countTarget.textContent, "1 selected")
})

test("columns submit hidden fields and keyboard reordering changes DOM order", () => {
  const columns = new Columns()
  const hidden = { disabled: true }
  const item = { querySelector: () => hidden }
  columns.visibility({ target: { checked: false, closest: () => item } })
  assert.equal(hidden.disabled, false)
  columns.visibility({ target: { checked: true, closest: () => item } })
  assert.equal(hidden.disabled, true)
  let moved
  item.nextElementSibling = { after: value => (moved = value) }
  columns.move({ key: "ArrowRight", preventDefault() {}, currentTarget: { closest: () => item, focus() {} } })
  assert.equal(moved, item)
})
