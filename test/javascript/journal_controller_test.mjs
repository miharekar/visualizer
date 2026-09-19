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
const { default: Dialog } = await import("../../app/javascript/controllers/journal_dialog_controller.js")

test("editor uses native modal lifecycle without submitting on dismissal", () => {
  const dialog = new Dialog()
  const calls = []
  dialog.element = { showModal: () => calls.push("open"), close: () => calls.push("close"), remove: () => calls.push("remove") }
  dialog.connect()
  dialog.close()
  dialog.remove()
  assert.deepEqual(calls, ["open", "close", "remove"])
})

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

test("columns stage reset, drag with a floating preview, and discard changes on cancel or close", t => {
  const columns = new Columns()
  const classes = () => {
    const values = new Set()
    return { add: (...names) => names.forEach(name => values.add(name)), remove: name => values.delete(name), contains: name => values.has(name) }
  }
  const list = hidden => ({
    dataset: { hidden: String(hidden) },
    children: [],
    closest(selector) {
      return selector === "[data-column]" ? null : this
    },
    append(item) {
      if (item.parentElement) item.parentElement.children.splice(item.parentElement.children.indexOf(item), 1)
      this.children.push(item)
      item.parentElement = this
    }
  })
  const visible = list(false)
  const hidden = list(true)
  columns.listTargets = [visible, hidden]
  const item = field => {
    const column = {
      dataset: { column: field },
      classList: classes(),
      getBoundingClientRect: () => ({ left: 100, top: 20, bottom: 60, width: 80, height: 40 }),
      cloneNode() {
        return {
          classList: classes(),
          style: {},
          removeAttribute() {},
          setAttribute() {},
          remove() {
            previews.splice(previews.indexOf(this), 1)
          }
        }
      },
      closest(selector) {
        return selector === "[data-column]" ? this : this.parentElement
      },
      before(other) {
        this.parentElement.append(other)
        const items = this.parentElement.children
        items.splice(items.indexOf(other), 1)
        items.splice(items.indexOf(this), 0, other)
      },
      after(other) {
        this.before(other)
        const items = this.parentElement.children
        items.splice(items.indexOf(other), 1)
        items.splice(items.indexOf(this) + 1, 0, other)
      }
    }
    column.input = { disabled: true, closest: () => column.parentElement }
    column.grip = { closest: () => column }
    visible.append(column)
    return column
  }
  const first = item("dose")
  const second = item("yield")
  columns.resetTarget = { disabled: true }
  columns.formTarget = {
    innerHTML: "saved form HTML",
    querySelectorAll: selector => {
      const items = [...visible.children, ...hidden.children]
      return selector === "[data-column]" ? items : items.map(column => column.input)
    },
    requestSubmit: () => assert.fail("Changes must remain staged")
  }
  let captured = false
  columns.panelTarget = {
    classList: classes(),
    dataset: { defaults: JSON.stringify(["yield"]) },
    setPointerCapture: () => (captured = true),
    hasPointerCapture: () => captured,
    releasePointerCapture: () => (captured = false)
  }
  const previews = []
  let destination = hidden
  t.mock.method(globalThis, "fetch", () => assert.fail("Changes must not make requests"))
  globalThis.document = { body: { append: preview => previews.push(preview) }, elementFromPoint: () => destination }
  t.after(() => delete globalThis.document)
  columns.connect()
  columns.reset()
  assert.deepEqual(visible.children, [second])
  assert.deepEqual(hidden.children, [first])
  assert.equal(columns.resetTarget.disabled, false)
  columns.serialize()
  assert.equal(columns.resetTarget.disabled, false)
  assert.equal(first.input.disabled, false)
  assert.equal(second.input.disabled, true)

  const pointer = { button: 0, isPrimary: true, pointerId: 1, clientX: 110, clientY: 30, preventDefault() {}, currentTarget: first.grip }
  columns.start(pointer)
  assert.equal(captured, true)
  assert.equal(columns.resetTarget.disabled, true)
  assert.equal(previews.length, 1)
  assert.equal(previews[0].classList.contains("pointer-events-none"), true)
  assert.equal(previews[0].classList.contains("z-50"), true)
  assert.equal(previews[0].style.transform, "translate(100px, 20px)")
  assert.equal(first.classList.contains("opacity-50"), true)
  destination = second
  columns.drag({ ...pointer, clientX: 160, clientY: 50 })
  assert.equal(previews[0].style.transform, "translate(150px, 40px)")
  assert.deepEqual(visible.children, [second, first])
  columns.drag({ ...pointer, clientX: 160, clientY: 50 })
  assert.deepEqual(visible.children, [second, first])
  columns.drag(pointer)
  assert.deepEqual(visible.children, [first, second])
  destination = visible
  columns.drag({ ...pointer, clientX: 95 })
  assert.deepEqual(visible.children, [first, second])
  columns.drag(pointer)
  assert.deepEqual(visible.children, [first, second])
  destination = hidden
  columns.drag(pointer)
  assert.deepEqual(hidden.children, [first])
  columns.finish(pointer)
  assert.equal(captured, false)
  assert.equal(columns.dragged, null)
  assert.equal(previews.length, 0)
  assert.equal(first.classList.contains("opacity-50"), false)
  columns.serialize()
  assert.equal(first.input.disabled, false)
  assert.equal(second.input.disabled, true)

  for (const close of ["cancel", "toggle"]) {
    columns.panelTarget.classList.remove("hidden")
    columns.formTarget.innerHTML = "staged form HTML"
    columns.start(pointer)
    columns[close]()
    assert.equal(columns.formTarget.innerHTML, "saved form HTML")
    assert.equal(columns.panelTarget.classList.contains("hidden"), true)
    assert.equal(previews.length, 0)
    assert.equal(captured, false)
  }
  columns.toggle()
  assert.equal(columns.panelTarget.classList.contains("hidden"), false)
  columns.start(pointer)
  columns.disconnect()
  assert.equal(previews.length, 0)
  assert.equal(captured, false)
})
