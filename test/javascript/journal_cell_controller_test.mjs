import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    return next(specifier, context)
  }
})
globalThis.CSS = { escape: value => value }
const { default: Cell } = await import("../../app/javascript/controllers/journal_cell_controller.js")

const build = (value, defaultValue) => {
  const cell = new Cell()
  const dataset = {}
  cell.element = {
    dataset,
    toggleAttribute: (name, force) => (force ? (dataset.unsaved = "") : delete dataset.unsaved),
    hasAttribute: name => name === "data-unsaved" && "unsaved" in dataset
  }
  cell.inputTarget = { value, defaultValue, validity: { badInput: false } }
  cell.errorTarget = {}
  return cell
}

test("cell is unsaved only while its value differs from the rendered one", () => {
  const cell = build("50", "50")
  cell.inputTarget.value = "87"
  cell.dirty()
  assert.equal(cell.element.hasAttribute("data-unsaved"), true)
  cell.inputTarget.value = "50"
  cell.dirty()
  assert.equal(cell.element.hasAttribute("data-unsaved"), false)
})

test("cell re-rendered after a 422 stays unsaved when reverted to the attempted value", () => {
  const cell = build("87", "87")
  cell.element.dataset.unsaved = ""
  cell.connect()
  cell.inputTarget.value = "50"
  cell.dirty()
  cell.inputTarget.value = "87"
  cell.dirty()
  assert.equal(cell.element.hasAttribute("data-unsaved"), true)
})

test("failed save keeps the cell unsaved after reverting", () => {
  const cell = build("50", "50")
  cell.connect()
  cell.complete({ detail: { fetchResponse: null } })
  cell.inputTarget.value = "51"
  cell.dirty()
  cell.inputTarget.value = "50"
  cell.dirty()
  assert.equal(cell.element.hasAttribute("data-unsaved"), true)
})

test("unparseable number input counts as unsaved", () => {
  const cell = build("", "")
  cell.connect()
  cell.inputTarget.validity.badInput = true
  cell.dirty()
  assert.equal(cell.element.hasAttribute("data-unsaved"), true)
  cell.inputTarget.validity.badInput = false
  cell.dirty()
  assert.equal(cell.element.hasAttribute("data-unsaved"), false)
})

test("failed save keeps the cell unsaved even when the value equals the rendered one", () => {
  const cell = build("50", "50")
  cell.complete({ detail: { fetchResponse: null } })
  assert.equal(cell.element.hasAttribute("data-unsaved"), true)
})

test("Enter moves to the next row with an editable control in the column and skips the rest", () => {
  const controls = [
    {
      focus() {
        this.focused = true
      },
      select() {}
    },
    null,
    {
      focus() {
        this.focused = true
      },
      select() {}
    }
  ]
  const rows = controls.map(control => ({ querySelector: () => control }))
  rows.forEach((row, index) => {
    row.previousElementSibling = rows[index - 1] ?? null
    row.nextElementSibling = rows[index + 1] ?? null
  })
  const cell = build("50", "50")
  const navigate = (from, shiftKey) => {
    cell.element.closest = () => ({ dataset: { column: "duration" }, parentElement: rows[from] })
    let prevented = false
    cell.navigate({ key: "Enter", shiftKey, preventDefault: () => (prevented = true) })
    assert.equal(prevented, true)
  }
  navigate(0, false)
  assert.equal(controls[2].focused, true)
  controls[2].focused = false
  navigate(2, true)
  assert.equal(controls[0].focused, true)
  controls[0].focused = false
  navigate(2, false)
  assert.equal(controls[0].focused || controls[2].focused, false)
})
