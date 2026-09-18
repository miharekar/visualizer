import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["rows", "row", "table", "selection", "status", "undo", "retry", "reload", "search", "columnList", "draft", "draftForm", "dialog", "dialogForm", "dialogTitle", "coffeeFields", "fieldFields", "tagFields", "noteFields", "apply"]
  static values = { url: String, createUrl: String, columnsUrl: String, timezone: String }

  connect() {
    this.queue = []
    this.reverts = new Map()
    this.pending = new Map()
    this.busy = false
    this.failures = new Map()
    this.dialogIds = []
  }

  disconnect() {
    clearTimeout(this.searchTimer)
  }

  get selectedRows() {
    return [...this.rowsTarget.querySelectorAll("tr")].filter(row => row.querySelector("[data-selection]").checked)
  }

  row(id) {
    return this.rowsTarget.querySelector(`[data-shot-id="${CSS.escape(id)}"]`)
  }

  cell(row, field) {
    return row.querySelector(`[data-column="${CSS.escape(field)}"]`)
  }

  select() {
    this.selectionTarget.textContent = `${this.selectedRows.length} selected`
  }

  selectAll(event) {
    this.rowsTarget.querySelectorAll("[data-selection]").forEach(input => {
      input.checked = event.target.checked
    })
    this.select()
  }

  edit(event) {
    const cell = event.currentTarget.closest("td")
    const row = cell.closest("tr")
    const field = cell.dataset.column
    if (field === "coffee") return this.openDialog("coffee", [row.dataset.shotId])
    if (["espresso_notes", "bean_notes", "private_notes"].includes(field)) return this.openNote(row, field)
  }

  focus(event) {
    event.target.dataset.original = event.target.value
  }

  key(event) {
    if (event.key === "Escape") {
      event.target.value = event.target.dataset.original
      event.target.dispatchEvent(new Event("input", { bubbles: true }))
      event.target.blur()
    } else if (event.key === "Enter") {
      event.preventDefault()
      const inputs = [...this.tableTarget.querySelectorAll("td:not(.hidden) [data-editor]")]
      const index = inputs.indexOf(event.target)
      event.target.blur()
      inputs[index + (event.shiftKey ? -1 : 1)]?.focus()
    }
  }

  commit(event) {
    const input = event.target
    const cell = input.closest("td")
    if (input.value === input.dataset.original) return
    const value = input.value
    const field = cell.dataset.column
    input.dataset.original = value
    this.save([cell.closest("tr").dataset.shotId], field, () => this.attributes(field, value))
  }

  attributes(field, value) {
    return field.startsWith("metadata:") ? { metadata: { [field.slice(9)]: value } } : { [field]: value }
  }

  save(ids, field, attributes) {
    const keys = ids.map(id => `${id}:${field}`)
    this.enqueue(async () => {
      const previous = Object.fromEntries(ids.map(id => [id, this.cell(this.row(id), field)?.dataset.value || ""]))
      const changes = ids.map(id => ({ id, version: this.row(id).dataset.version, attributes: attributes(this.row(id)) }))
      const result = await this.request(this.urlValue, "PATCH", { changes })
      this.finishPending(keys)
      this.renderRows(result.rows)
      const operation = { token: result.undo, ids, field, previous }
      keys.forEach(key => this.reverts.set(key, operation))
      this.lastOperation = operation
      this.undoTarget.classList.remove("hidden")
      this.undoTarget.textContent = ids.length > 1 ? `Undo change to ${ids.length} shots` : "Undo last change"
      this.refreshReverts()
    }, keys)
  }

  enqueue(operation, keys = [], key = keys.join("|") || crypto.randomUUID()) {
    this.failures.delete(key)
    operation.keys = keys
    operation.key = key
    operation.settled = false
    keys.forEach(cell => this.pending.set(cell, (this.pending.get(cell) || 0) + 1))
    this.queue.push(operation)
    this.drain()
  }

  async drain() {
    if (this.busy || !this.queue.length) return
    this.busy = true
    const operation = this.queue.shift()
    this.currentOperation = operation
    this.failures.delete(operation.key)
    this.statusTarget.textContent = "Saving…"
    try {
      await operation()
    } catch (error) {
      this.finishPending(operation.keys)
      operation.error = error.message
      this.failures.set(operation.key, operation)
    } finally {
      this.finishPending(operation.keys)
      this.busy = false
      this.currentOperation = null
      this.refreshStatus()
      this.drain()
      if (this.searchPending && !this.hasUnsavedChanges()) this.search()
    }
  }

  finishPending(keys) {
    if (this.currentOperation?.settled) return
    if (this.currentOperation) this.currentOperation.settled = true
    keys.forEach(key => {
      const count = (this.pending.get(key) || 0) - 1
      if (count > 0) this.pending.set(key, count)
      else this.pending.delete(key)
    })
  }

  failureForCell(key) {
    return [...this.failures.values()].find(operation => operation.keys.includes(key))
  }

  refreshStatus() {
    const failures = [...this.failures.values()]
    this.statusTarget.textContent = failures.length ? `Couldn't save: ${failures[0].error}. Correct the value or retry.` : "Saved"
    this.retryTarget.classList.toggle("hidden", !failures.length)
    this.reloadTarget.classList.toggle("hidden", !failures.length)
    this.rowsTarget.querySelectorAll("[data-editor]").forEach(input => {
      const cell = input.closest("td")
      const failure = this.failureForCell(`${cell.closest("tr").dataset.shotId}:${cell.dataset.column}`)
      input.setAttribute("aria-invalid", failure ? "true" : "false")
      input.title = failure?.error || ""
    })
  }

  retry() {
    ;[...this.failures.values()].forEach(operation => this.enqueue(operation, operation.keys, operation.key))
  }

  reload() {
    if (!window.confirm("Discard pending changes and reload saved values?")) return
    this.leaving = true
    window.location.reload()
  }

  async request(url, method, body) {
    const response = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
      body: JSON.stringify(body)
    })
    if (response.status === 204) return {}
    const data = await response.json().catch(() => ({}))
    if (!response.ok || response.redirected) throw new Error(data.error || "Request failed. Reload if your session has expired.")
    return data
  }

  renderRows(rows) {
    rows.forEach(({ id, html }) => {
      const fragment = document.createElement("template")
      fragment.innerHTML = `<table><tbody>${html}</tbody></table>`
      const incoming = fragment.content.querySelector("tr")
      const current = this.row(id)
      if (!current) {
        this.rowsTarget.prepend(incoming)
      } else {
        Object.assign(current.dataset, incoming.dataset)
        incoming.querySelectorAll("[data-column]").forEach(cell => {
          const previous = this.cell(current, cell.dataset.column)
          const active = previous.querySelector("[data-editor]") === document.activeElement
          const key = `${id}:${cell.dataset.column}`
          if (!this.pending.has(key) && !this.failureForCell(key) && !active) previous.replaceWith(cell)
          else previous.dataset.value = cell.dataset.value
        })
      }
    })
    this.applyColumns()
    this.refreshReverts()
    this.select()
  }

  refreshReverts() {
    this.rowsTarget.querySelectorAll("[data-revert]").forEach(button => {
      const cell = button.closest("td")
      const key = `${cell.closest("tr").dataset.shotId}:${cell.dataset.column}`
      button.classList.toggle("hidden", !this.reverts.has(key))
      const operation = this.reverts.get(key)
      const value = operation?.previous[cell.closest("tr").dataset.shotId]
      button.title = `Restore previous value: ${value || "empty"}`
    })
  }

  revert(event) {
    const cell = event.currentTarget.closest("td")
    this.performUndo(this.reverts.get(`${cell.closest("tr").dataset.shotId}:${cell.dataset.column}`))
  }

  undo() {
    this.performUndo(this.lastOperation)
  }

  performUndo(operation) {
    if (!operation) return
    this.enqueue(async () => {
      const result = await this.request(this.urlValue, "PATCH", { undo: operation.token })
      for (const [key, value] of this.reverts) if (value === operation) this.reverts.delete(key)
      if (this.lastOperation === operation) {
        this.lastOperation = null
        this.undoTarget.classList.add("hidden")
      }
      this.renderRows(result.rows)
    })
  }

  bulkCoffee() {
    this.openSelected("coffee")
  }
  bulkField() {
    this.openSelected("field")
  }
  bulkTags() {
    this.openSelected("tags")
  }

  openSelected(mode) {
    const ids = this.selectedRows.map(row => row.dataset.shotId)
    if (!ids.length) {
      this.statusTarget.textContent = "Select shots first"
      return
    }
    this.openDialog(mode, ids)
  }

  openDialog(mode, ids) {
    this.dialogMode = mode
    this.dialogIds = ids
    this.dialogFormTarget.reset()
    for (const [name, target] of Object.entries({ coffee: this.coffeeFieldsTarget, field: this.fieldFieldsTarget, tags: this.tagFieldsTarget, note: this.noteFieldsTarget })) {
      target.classList.toggle("hidden", name !== mode)
    }
    this.applyTarget.textContent = mode === "note" ? "Save notes" : "Apply to selected shots"
    this.dialogTitleTarget.textContent = { coffee: "Assign coffee", field: "Set field", tags: "Add/remove tags", note: "Notes" }[mode]
    if (mode === "coffee" && ids.length === 1) {
      const row = this.row(ids[0])
      for (const name of ["coffee_bag_id", "canonical_coffee_bag_id", "bean_brand", "bean_type"]) {
        const input = this.coffeeFieldsTarget.querySelector(`[name="${name}"]`)
        if (input) input.value = name === "coffee_bag_id" ? row.dataset.coffeeBagId : name === "canonical_coffee_bag_id" ? row.dataset.canonicalCoffeeBagId : this.cell(row, name)?.dataset.value || ""
      }
    }
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }

  saveDialog(event) {
    event.preventDefault()
    const data = new FormData(this.dialogFormTarget)
    if (this.dialogMode === "note") {
      const value = this.noteFieldsTarget.querySelector("lexxy-editor").value
      const field = this.noteField
      if (value !== this.noteValue) this.save([...this.dialogIds], field, () => this.attributes(field, value))
    } else if (this.dialogMode === "coffee") {
      const attributes = {}
      this.coffeeFieldsTarget.querySelectorAll("[name]").forEach(input => {
        attributes[input.name] = input.value
      })
      if (attributes.canonical_coffee_bag_id) {
        delete attributes.bean_brand
        delete attributes.bean_type
      }
      this.save(this.dialogIds, "coffee", () => attributes)
    } else if (this.dialogMode === "field") {
      const field = data.get("field")
      this.save(this.dialogIds, field, () => this.attributes(field, data.get("value")))
    } else if (this.dialogMode === "tags") {
      const names = data
        .get("tags")
        .split(",")
        .map(name =>
          name
            .trim()
            .toLowerCase()
            .replace(/[^\w\s-]/g, "")
        )
        .filter(Boolean)
      this.save(this.dialogIds, "tag_list", row => {
        const current = (this.cell(row, "tag_list").dataset.value || "").split(",").filter(Boolean)
        return { tag_list: data.get("tag_action") === "add" ? [...new Set([...current, ...names])] : current.filter(name => !names.includes(name)) }
      })
    }
    this.closeDialog()
  }

  openNote(row, field) {
    this.openDialog("note", [row.dataset.shotId])
    this.noteField = field
    const value = this.cell(row, field).dataset.value
    const editor = this.noteFieldsTarget.querySelector("lexxy-editor")
    editor.value = value
    this.noteValue = value
    this.dialogTitleTarget.textContent = this.columnListTarget.querySelector(`[data-column-choice="${field}"] label`).textContent.trim()
  }

  closeDialog(event) {
    event?.preventDefault()
    this.dialogTarget.close()
    this.dialogMode = null
  }

  compare() {
    const rows = this.selectedRows
    if (rows.length !== 2 || rows.some(row => row.dataset.chart !== "true")) {
      this.statusTarget.textContent = "Select two shots with chart data to compare"
      return
    }
    if (this.hasUnsavedChanges() && !window.confirm("Changes are still pending. Leave Journal?")) return
    window.location.assign(`/shots/${rows[0].dataset.shotId}/compare/${rows[1].dataset.shotId}`)
  }

  newShot() {
    if (this.draftTarget.classList.contains("hidden")) {
      this.entryId = crypto.randomUUID()
      this.draftFormTarget.reset()
      const parts = Object.fromEntries(new Intl.DateTimeFormat("en-CA", { timeZone: this.timezoneValue, year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit", hourCycle: "h23" }).formatToParts(new Date()).map(part => [part.type, part.value]))
      this.draftFormTarget.elements.start_time.value = `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}`
    }
    this.draftTarget.classList.remove("hidden")
    this.draftFormTarget.querySelector("select, input:not([type=hidden])")?.focus()
  }

  cancelDraft() {
    if (this.creating && this.currentOperation?.key === "create") return
    if (this.creationOperation) {
      const index = this.queue.indexOf(this.creationOperation)
      if (index !== -1) this.queue.splice(index, 1)
    }
    this.failures.delete("create")
    this.creating = false
    this.draftTarget.classList.add("hidden")
    this.draftFormTarget.reset()
    this.refreshStatus()
    this.drain()
  }

  create(event) {
    event.preventDefault()
    if (this.creating) {
      if (this.failures.has("create")) this.enqueue(this.creationOperation, [], "create")
      return
    }
    this.creating = true
    const entry_id = this.entryId
    this.creationOperation = async () => {
      const shot = Object.fromEntries([...this.draftFormTarget.querySelectorAll("[data-shot-field]")].map(input => [input.name, input.value]))
      if (shot.canonical_coffee_bag_id) {
        delete shot.bean_brand
        delete shot.bean_type
      }
      const result = await this.request(this.createUrlValue, "POST", { shot, entry_id })
      this.renderRows(result.rows)
      this.creating = false
      this.creationOperation = null
      this.cancelDraft()
      this.statusTarget.textContent = "Shot added; pinned here until next search"
    }
    this.enqueue(this.creationOperation, [], "create")
  }

  columns() {
    this.applyColumns()
    const choices = [...this.columnListTarget.children]
    const columns = { order: choices.map(item => item.dataset.columnChoice), hidden: choices.filter(item => !item.querySelector("input").checked).map(item => item.dataset.columnChoice) }
    this.enqueue(() => this.request(this.columnsUrlValue, "PATCH", { columns }), [], "columns")
  }

  moveColumn(event) {
    const item = event.currentTarget.closest("[data-column-choice]")
    const direction = Number(event.currentTarget.dataset.direction)
    if (direction < 0 && item.previousElementSibling) item.previousElementSibling.before(item)
    if (direction > 0 && item.nextElementSibling) item.nextElementSibling.after(item)
    this.columns()
    event.currentTarget.focus()
  }

  applyColumns() {
    this.tableTarget.querySelectorAll("tr").forEach(row => this.rowTargetConnected(row))
  }

  rowTargetConnected(row) {
    if (!this.hasColumnListTarget) return
    ;[...this.columnListTarget.children].forEach(item => {
      const cell = this.cell(row, item.dataset.columnChoice)
      if (!cell) return
      cell.classList.toggle("hidden", !item.querySelector("input").checked)
      row.append(cell)
    })
  }

  beforeStream(event) {
    const stream = event.target
    if (stream.getAttribute("target") !== "journal-rows") return
    if (stream.getAttribute("action") === "update") {
      this.reverts.clear()
      this.lastOperation = null
      this.undoTarget.classList.add("hidden")
      this.selectionTarget.textContent = "0 selected"
      return
    }
    stream.templateElement.content.querySelectorAll("[data-shot-id]").forEach(row => {
      if (this.row(row.dataset.shotId)) row.remove()
    })
  }

  search() {
    this.searchPending = true
    clearTimeout(this.searchTimer)
    this.searchTimer = setTimeout(() => {
      if (!this.hasUnsavedChanges()) {
        this.searchPending = false
        this.searchTarget.requestSubmit()
      }
    }, 300)
  }

  hasUnsavedChanges() {
    const editing = this.rowsTarget.querySelector("[data-editor]:focus")
    const dirtyCell = editing && editing.value !== editing.dataset.original
    const dirtyNote = this.dialogMode === "note" && this.noteFieldsTarget.querySelector("lexxy-editor").value !== this.noteValue
    return this.busy || this.queue.length > 0 || this.failures.size > 0 || !this.draftTarget.classList.contains("hidden") || dirtyCell || dirtyNote
  }

  beforeVisit(event) {
    if (this.hasUnsavedChanges() && !window.confirm("Unsaved changes will be lost. Leave Journal?")) event.preventDefault()
  }

  beforeSubmit(event) {
    if (event.target !== this.searchTarget) return
    if (this.hasUnsavedChanges()) {
      event.preventDefault()
      this.statusTarget.textContent = "Finish or cancel pending edits before searching"
      this.searchPending = this.queue.length > 0
    }
  }

  beforeUnload(event) {
    if (this.leaving || !this.hasUnsavedChanges()) return
    event.preventDefault()
    event.returnValue = ""
  }
}
