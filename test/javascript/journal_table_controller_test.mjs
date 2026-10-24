import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    if (specifier === "@rails/request.js") return { url: "data:text/javascript,export const patch = (...args) => globalThis.patchStub(...args)", shortCircuit: true }
    return next(specifier, context)
  }
})
globalThis.CSS = { escape: value => value }
globalThis.document = {
  createElement: () => ({
    remove() {
      this.removed = true
    }
  })
}
const { default: Table } = await import("../../app/javascript/controllers/journal_table_controller.js")

const tick = () => new Promise(resolve => setTimeout(resolve, 0))
const streamResponse = (status = 200) => ({ isTurboStream: true, ok: status < 300, unprocessableEntity: status === 422 })

const build = ({ value = "50", defaultValue = value, column = "espresso_enjoyment", id = "shot-1", valid = true } = {}) => {
  const table = new Table()
  table.urlValue = "/shots/journal"
  const dataset = { column }
  const cell = {
    dataset,
    isConnected: true,
    toggleAttribute: (name, force) => (force ? (dataset[name.slice(5)] = "") : delete dataset[name.slice(5)]),
    hasAttribute: name => name.slice(5) in dataset,
    querySelector: () => cell.error ?? null,
    append: element => {
      cell.error = element
      element.remove = () => {
        element.removed = true
        if (cell.error === element) cell.error = null
      }
    },
    closest: selector => (selector === "tr" ? { dataset: { id } } : cell)
  }
  const input = {
    value,
    defaultValue,
    readOnly: false,
    style: {},
    validity: { badInput: false },
    matches: () => true,
    closest: () => cell,
    reportValidity: () => valid,
    focus() {
      this.focused = true
    },
    select() {}
  }
  cell.parentElement = { nextElementSibling: null, previousElementSibling: null }
  return { table, cell, input }
}

const eventFor = (input, extra = {}) => ({
  target: input,
  key: "Enter",
  shiftKey: false,
  preventDefault() {
    this.prevented = true
  },
  ...extra
})

test("cell is unsaved only while its value differs from the rendered one", () => {
  const { table, cell, input } = build({ value: "50" })
  input.value = "87"
  table.dirty(eventFor(input))
  assert.equal(cell.hasAttribute("data-unsaved"), true)
  input.value = "50"
  table.dirty(eventFor(input))
  assert.equal(cell.hasAttribute("data-unsaved"), false)
})

test("a failed cell stays unsaved when reverted", () => {
  const { table, cell, input } = build({ value: "87" })
  cell.dataset.failed = ""
  cell.dataset.unsaved = ""
  input.value = "50"
  table.dirty(eventFor(input))
  input.value = "87"
  table.dirty(eventFor(input))
  assert.equal(cell.hasAttribute("data-unsaved"), true)
})

test("unparseable number input counts as unsaved", () => {
  const { table, cell, input } = build({ value: "" })
  input.validity.badInput = true
  table.dirty(eventFor(input))
  assert.equal(cell.hasAttribute("data-unsaved"), true)
  input.validity.badInput = false
  table.dirty(eventFor(input))
  assert.equal(cell.hasAttribute("data-unsaved"), false)
})

test("enjoyment recolours while typing, clamps, and ignores unparseable input", () => {
  const { table, input } = build()
  input.value = "50"
  table.dirty(eventFor(input))
  assert.equal(input.style.backgroundColor, "hsl(60, 70%, 50%)")
  input.value = "250"
  table.dirty(eventFor(input))
  assert.equal(input.style.backgroundColor, "hsl(120, 70%, 50%)")
  input.value = "-4"
  table.dirty(eventFor(input))
  assert.equal(input.style.backgroundColor, "hsl(0, 70%, 50%)")
  input.value = ""
  table.dirty(eventFor(input))
  assert.equal(input.style.backgroundColor, "hsl(0, 70%, 50%)")
})

test("other columns are not recoloured", () => {
  const { table, input } = build({ column: "bean_weight" })
  input.value = "18"
  table.dirty(eventFor(input))
  assert.equal(input.style.backgroundColor, undefined)
})

test("a save patches the table url with field and shot, urlencoded, and stays locked until the stream renders", async () => {
  const { table, cell, input } = build({ column: "duration", id: "abc", value: "28" })
  const calls = []
  globalThis.patchStub = async (url, options) => {
    calls.push([url, options])
    return streamResponse()
  }
  input.value = "30"
  table.save({ target: input })
  await tick()
  assert.deepEqual(calls, [["/shots/journal?field=duration&ids%5B%5D=abc", { body: "value=30", contentType: "application/x-www-form-urlencoded", responseKind: "turbo-stream" }]])
  assert.equal(input.readOnly, true)
  assert.equal(cell.hasAttribute("data-saving"), true)
})

test("Enter, change and blur send one request per edit", async () => {
  const { table, input } = build()
  let requests = 0
  globalThis.patchStub = async () => {
    requests++
    return new Promise(() => {})
  }
  input.value = "70"
  table.dirty(eventFor(input))
  table.navigate(eventFor(input))
  table.save({ target: input })
  table.save({ target: input })
  await tick()
  assert.equal(requests, 1)
})

test("invalid input sends nothing and keeps focus", async () => {
  const { table, cell, input } = build({ valid: false })
  let requests = 0
  globalThis.patchStub = async () => requests++
  input.value = "101"
  table.dirty(eventFor(input))
  const event = eventFor(input)
  table.navigate(event)
  table.save({ target: input })
  await tick()
  assert.equal(requests, 0)
  assert.equal(event.prevented, true)
  assert.equal(cell.hasAttribute("data-saving"), false)
  assert.equal(input.readOnly, false)
})

test("a 422 stream response is not a failure", async () => {
  const { table, cell, input } = build()
  globalThis.patchStub = async () => streamResponse(422)
  table.save({ target: input })
  await tick()
  assert.equal(cell.hasAttribute("data-failed"), false)
  assert.equal(cell.hasAttribute("data-saving"), true)
})

for (const [name, patchStub] of [
  ["network rejection", async () => Promise.reject(new TypeError("Failed to fetch"))],
  ["non-stream response", async () => ({ isTurboStream: null, ok: true, unprocessableEntity: false })],
  ["plain 404", async () => ({ isTurboStream: null, ok: false, unprocessableEntity: false })],
  ["stream with a server error status", async () => streamResponse(500)]
]) {
  test(`${name} keeps the value, unlocks the input and shows the retry message without throwing`, async () => {
    const { table, cell, input } = build()
    globalThis.patchStub = patchStub
    input.value = "87"
    table.save({ target: input })
    await tick()
    assert.equal(input.value, "87")
    assert.equal(input.readOnly, false)
    assert.equal(cell.hasAttribute("data-saving"), false)
    assert.equal(cell.hasAttribute("data-failed"), true)
    assert.equal(cell.hasAttribute("data-unsaved"), true)
    assert.equal(cell.error.textContent, "Not saved. Press Enter to retry.")
    input.value = "50"
    table.dirty(eventFor(input))
    assert.equal(cell.hasAttribute("data-unsaved"), true)
  })
}

test("a retry clears the old message and a second failure shows a new one", async () => {
  const { table, cell, input } = build()
  globalThis.patchStub = async () => ({ isTurboStream: null })
  table.save({ target: input })
  await tick()
  const first = cell.error
  assert.equal(first.textContent, "Not saved. Press Enter to retry.")
  table.save({ target: input })
  assert.equal(first.removed, true)
  assert.equal(cell.error, null)
  await tick()
  assert.notEqual(cell.error, first)
  assert.equal(cell.error.textContent, "Not saved. Press Enter to retry.")
})

test("a failure for a cell that left the page does nothing", async () => {
  const { table, cell, input } = build()
  globalThis.patchStub = async () => {
    cell.isConnected = false
    throw new TypeError("Failed to fetch")
  }
  table.save({ target: input })
  await tick()
  assert.equal(cell.hasAttribute("data-failed"), false)
})

test("Enter moves down and Shift+Enter up the column, skipping rows without a control", () => {
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
  const { table, cell, input } = build({ column: "duration" })
  const press = (from, shiftKey) => {
    cell.parentElement = rows[from]
    const event = eventFor(input, { shiftKey })
    table.navigate(event)
    assert.equal(event.prevented, true)
  }
  press(0, false)
  assert.equal(controls[2].focused, true)
  controls[2].focused = false
  press(2, true)
  assert.equal(controls[0].focused, true)
  controls[0].focused = false
  press(2, false)
  assert.equal(controls[0].focused || controls[2].focused, false)
})

test("Enter on an unchanged cell moves without saving", async () => {
  const { table, cell, input } = build({ column: "duration" })
  const control = {
    focus() {
      this.focused = true
    },
    select() {}
  }
  cell.parentElement = { nextElementSibling: { querySelector: () => control, nextElementSibling: null } }
  let requests = 0
  globalThis.patchStub = async () => requests++
  table.navigate(eventFor(input))
  await tick()
  assert.equal(control.focused, true)
  assert.equal(requests, 0)
})

test("Enter on a changed cell saves, then moves", async () => {
  const { table, cell, input } = build({ column: "duration" })
  const control = {
    focus() {
      this.focused = true
    },
    select() {}
  }
  cell.parentElement = { nextElementSibling: { querySelector: () => control, nextElementSibling: null } }
  let requests = 0
  globalThis.patchStub = async () => {
    requests++
    return new Promise(() => {})
  }
  input.value = "31"
  table.dirty(eventFor(input))
  table.navigate(eventFor(input))
  assert.equal(requests, 1)
  assert.equal(control.focused, true)
})

test("events that do not come from a cell input are ignored", async () => {
  const { table, cell } = build()
  const checkbox = { matches: () => false, closest: () => cell, checked: true }
  let requests = 0
  globalThis.patchStub = async () => requests++
  const event = eventFor(checkbox)
  table.dirty(event)
  table.save(event)
  table.navigate(event)
  await tick()
  assert.equal(requests, 0)
  assert.equal(event.prevented, undefined)
  assert.equal(cell.hasAttribute("data-unsaved"), false)
  assert.equal(cell.hasAttribute("data-saving"), false)
})
