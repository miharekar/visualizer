import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    if (specifier === "@hotwired/stimulus") return { url: "data:text/javascript,export class Controller {}", shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: Selection } = await import("../../app/javascript/controllers/journal_selection_controller.js")

test("selection caps at 100, builds compare link, and resets", () => {
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
  selection.reset()
  assert.equal(selection.selected.length, 0)
  selection.checkboxTargets[0].checked = selection.checkboxTargets[1].checked = true
  selection.select()
  assert.equal(selection.compareTarget.href, "/shots/shot-0/compare/shot-1")
  selection.checkboxTargets.splice(1, 1)
  selection.checkboxTargetDisconnected()
  assert.equal(selection.countTarget.textContent, "1 selected")
})
