import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    const stubs = {
      "@hotwired/stimulus": "export class Controller {}",
      "el-transition": "export const enter = () => {}; export const leave = () => {}",
      "match-sorter": `export function matchSorter(items, value, options) {
        const matches = items.map((item, index) => ({ item, index })).filter(({ item }) => options.keys[0](item).includes(value))
        return (options.sorter ? options.sorter(matches) : matches.sort((a, b) => options.keys[0](a.item).localeCompare(options.keys[0](b.item)))).map(({ item }) => item)
      }`
    }
    if (Object.hasOwn(stubs, specifier)) return { url: `data:text/javascript,${encodeURIComponent(stubs[specifier])}`, shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: Modal } = await import("../../app/javascript/controllers/modal_controller.js")
const { default: Combobox } = await import("../../app/javascript/controllers/combobox_controller.js")

function combobox(ids = ["Zulu", "Alpha"]) {
  const controller = new Combobox()
  for (const [name, config] of Object.entries(Combobox.values)) controller[`${name}Value`] = config.default
  const classes = () => {
    const values = new Set()
    return { add: (...names) => names.forEach(name => values.add(name)), remove: (...names) => names.forEach(name => values.delete(name)), contains: name => values.has(name) }
  }
  const items = ids.map(id => Object.assign(new EventTarget(), { dataset: { id, name: id }, classList: classes(), scrollIntoView() {} }))
  const list = {
    children: items,
    classList: classes(),
    scrollIntoView() {},
    replaceChildren(...children) {
      this.children = children
      children.forEach((item, index) => {
        item.previousElementSibling = children[index - 1]
        item.nextElementSibling = children[index + 1]
      })
    },
    set innerHTML(value) {
      assert.equal(value, "", "Options must not be serialized and recreated")
      this.replaceChildren()
    },
    querySelectorAll(selector) {
      assert.equal(selector, "li")
      return this.children
    },
    querySelector(selector) {
      if (selector === ".is-selected") return this.children.find(item => item.classList.contains("is-selected"))
      assert.equal(selector, "li:not(.hidden)")
      return this.children.find(item => !item.classList.contains("hidden"))
    },
    contains(item) {
      return this.children.includes(item)
    }
  }
  controller.listTarget = list
  controller.inputTarget = { value: "", focus() {}, blur: () => assert.fail("Focus must remain native") }
  controller.hiddenInputTarget = Object.assign(new EventTarget(), { value: "" })
  controller.element = { contains: item => item === controller.inputTarget || list.contains(item) }
  controller.connect()
  return controller
}

test("Enter on Cancel leaves native activation alone; Escape still dismisses confirmation", () => {
  const modal = new Modal()
  modal.initialize()
  modal.toggleableTargets = []
  modal.performClick = () => assert.fail("Cancel must never confirm deletion")
  modal.show()
  const cancel = { tagName: "BUTTON", type: "button", click: () => modal.hide() }
  modal.keydown({ key: "Enter", target: cancel, preventDefault: () => assert.fail("Native Cancel activation must remain available") })
  assert.equal(modal.modalShown, true)
  cancel.click()
  assert.equal(modal.modalShown, false)
  modal.show()
  const escape = new Event("keydown", { cancelable: true })
  escape.key = "Escape"
  modal.keydown(escape)
  assert.equal(escape.defaultPrevented, true)
  assert.equal(modal.modalShown, false)
})

test("filter reorders original nodes and retains listeners and caller ordering", () => {
  const controller = combobox()
  const [zulu, alpha] = controller.allItems
  let clicks = 0
  alpha.addEventListener("click", () => clicks++)
  controller.show()
  assert.equal(controller.listTarget.children[0], alpha)
  assert.equal(controller.listTarget.children[1], zulu)
  controller.markAsActive(zulu)
  controller.inputTarget.value = "Alpha"
  controller.filter()
  assert.deepEqual(controller.listTarget.children, [alpha])
  assert.equal(controller.active, null)
  assert.equal(zulu.classList.contains(controller.activeClassesValue[1]), false)
  controller.inputTarget.value = ""
  controller.preserveOrderValue = true
  controller.filter()
  assert.equal(controller.listTarget.children[0], zulu)
  assert.equal(controller.listTarget.children[1], alpha)
  alpha.dispatchEvent(new Event("click"))
  assert.equal(clicks, 1)
})

test("reselecting the same custom option restores its full name", () => {
  const controller = combobox()
  controller.allowCustomValue = true
  controller.selectById("Alpha")
  const selected = controller.selected
  controller.show()
  controller.inputTarget.value = "Al"
  controller.filter()
  controller.select({ currentTarget: selected, preventDefault() {}, stopPropagation() {} })
  assert.equal(controller.inputTarget.value, "Alpha")
  assert.equal(controller.hiddenInputTarget.value, "Alpha")
  assert.equal(controller.selected, selected)
})

test("active option lookup accepts quotes, backslashes, selector syntax, and empty IDs", () => {
  const controller = combobox(["plain", 'a"b', "a\\b", 'x"] [data-id="plain', ""])
  controller.show()
  for (const item of controller.allItems) {
    controller.active = item
    assert.equal(controller.getActive(), item)
  }
})

test("either arrow opens a closed list before highlighting, including after Escape", () => {
  for (const method of ["highlightNext", "highlightPrevious"]) {
    const controller = combobox()
    for (let attempt = 0; attempt < 2; attempt++) {
      const event = new Event("keydown", { cancelable: true })
      controller[method](event)
      assert.equal(event.defaultPrevented, true)
      assert.equal(controller.shown, true)
      assert.equal(controller.listTarget.classList.contains("hidden"), false)
      assert.ok(controller.listTarget.contains(controller.active))
      assert.equal(controller.active.classList.contains(controller.activeClassesValue[1]), true)
      controller.hide(event)
    }
  }
})

test("keyboard, touch click, and programmatic selection keep values and change events without forcing blur", () => {
  for (const mode of ["keyboard", "touch", "programmatic"]) {
    const controller = combobox()
    let changes = 0
    controller.hiddenInputTarget.addEventListener("change", () => changes++)
    const selected = controller.allItems[1]
    if (mode === "programmatic") {
      controller.selectById(selected.dataset.id)
    } else {
      controller.show()
      controller.blur({ relatedTarget: null })
      assert.equal(controller.shown, true)
      controller.select({ currentTarget: mode === "touch" ? selected : controller.inputTarget, preventDefault() {}, stopPropagation() {} })
    }
    assert.equal(controller.inputTarget.value, selected.dataset.name)
    assert.equal(controller.hiddenInputTarget.value, selected.dataset.id)
    assert.equal(changes, 1)
    assert.equal(controller.shown, false)
    controller.show()
    controller.blur({ relatedTarget: {}, stopPropagation() {} })
    assert.equal(controller.shown, false)
  }
})
