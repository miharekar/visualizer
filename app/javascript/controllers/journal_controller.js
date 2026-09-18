import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["rows", "row", "table", "tableViewport", "selection", "selectionNotice", "bulkBar", "compare", "undo", "undoLabel", "undoError", "search", "searchNotice", "columnsPanel", "columnsButton", "columnsError", "columnList", "visibleColumns", "hiddenColumns", "draft", "draftForm", "draftError", "savedShot", "dialog", "dialogForm", "dialogError", "dialogTitle", "coffeeFields", "fieldFields", "tagFields", "noteFields", "apply"]
  static values = { url: String, cellsUrl: String, createUrl: String, columnsUrl: String, timezone: String, searchId: String, query: Object, maxBatch: Number }

  connect() {
    this.queue = []
    this.disconnected = false
    this.pendingRenders = new Map()
    this.partialRows = new Set()
    this.pending = new Map()
    this.busy = false
    this.failures = new Map()
    this.dialogIds = []
    this.undoHistory = []
    this.editEpoch = 0
    this.searchEpoch = 0
    this.dialogLoadVersion = 0
    if (this.hasTableViewportTarget) {
      this.viewportObserver = new ResizeObserver(() => this.sizeViewport())
      ;[this.element, document.querySelector("body > header"), document.querySelector("body > footer")].filter(Boolean).forEach(element => this.viewportObserver.observe(element))
      this.sizeViewport()
    }
  }

  disconnect() {
    this.disconnected = true
    this.pendingRenders.forEach(({ reject }) => reject(new Error("Page changed before rendering completed")))
    this.pendingRenders.clear()
    clearTimeout(this.searchTimer)
    cancelAnimationFrame(this.columnSaveFrame)
    this.viewportObserver?.disconnect()
    this.cancelColumnDrag()
  }

  sizeViewport() {
    const viewport = this.tableViewportTarget
    const footerHeight = document.querySelector("body > footer")?.offsetHeight || 0
    const bounds = viewport.getBoundingClientRect()
    const afterTable = Math.max(0, this.element.getBoundingClientRect().bottom - bounds.bottom)
    const available = window.innerHeight - bounds.top - window.scrollY - footerHeight - afterTable
    viewport.style.maxHeight = `${Math.max(0, available)}px`
  }

  get selectedRows() {
    return this.rowTargets.filter(row => row.querySelector("[data-selection]").checked)
  }

  get lastOperation() {
    return this.undoHistory.at(-1)
  }

  row(id) {
    return this.rowsTarget.querySelector(`[data-shot-id="${CSS.escape(id)}"]`)
  }

  cell(row, field) {
    return row.querySelector(`[data-column="${CSS.escape(field)}"]`)
  }

  select(event) {
    if (event?.target.checked && this.selectedRows.length > this.maxBatchValue) event.target.checked = false
    const count = this.selectedRows.length
    this.selectionTarget.textContent = `${count} selected`
    this.selectionNoticeTarget.textContent = count === this.maxBatchValue ? `Maximum ${this.maxBatchValue} shots per edit` : ""
    this.bulkBarTarget.classList.toggle("hidden", count === 0)
    this.bulkBarTarget.classList.toggle("flex", count > 0)
    this.compareTarget.classList.toggle("hidden", count !== 2)
  }

  selectAll(event) {
    this.rowsTarget.querySelectorAll("[data-selection]").forEach((input, index) => {
      input.checked = event.target.checked && index < this.maxBatchValue
    })
    this.select()
  }

  edit(event) {
    const cell = event.currentTarget.closest("td")
    const row = cell.closest("tr")
    const field = cell.dataset.column
    if (field === "coffee") return this.openDialog("coffee", [row.dataset.shotId])
    if (["espresso_notes", "bean_notes", "private_notes"].includes(field)) return this.openNote(row, field)
    if (field === "tag_list") {
      return this.openDialog("tags", [row.dataset.shotId])
    }
    this.openDialog("field", [row.dataset.shotId], field)
  }

  focus(event) {
    event.target.dataset.original = event.target.value
  }

  resizeInput(event) {
    event.currentTarget.style.width = `${Math.max(event.currentTarget.value.length, 1) + 3}ch`
  }

  key(event) {
    if (event.key === "Escape") {
      event.target.value = event.target.dataset.original
      event.target.dispatchEvent(new Event("input", { bubbles: true }))
      event.target.blur()
    } else if (event.key === "Enter") {
      event.preventDefault()
      const cell = event.target.closest("[data-column]")
      const rows = this.rowTargets
      const index = rows.indexOf(cell.closest("[data-shot-id]"))
      const nextRow = rows[index + (event.shiftKey ? -1 : 1)]
      const next = nextRow && this.cell(nextRow, cell.dataset.column)?.querySelector("[data-editor], [data-display]")
      event.target.blur()
      next?.focus()
      next?.select?.()
    }
  }

  commit(event) {
    const input = event.target
    const cell = input.closest("td")
    const key = `${cell.closest("tr").dataset.shotId}:${cell.dataset.column}`
    if (input.value === input.dataset.original && !this.failureForCell(key)) {
      queueMicrotask(() => this.resumeSearch())
      return
    }
    const value = input.value
    const field = cell.dataset.column
    input.dataset.original = value
    this.save([cell.closest("tr").dataset.shotId], field, () => this.attributes(field, value))
  }

  attributes(field, value) {
    return field.startsWith("metadata:") ? { metadata: { [field.slice(9)]: value } } : { [field]: value }
  }

  save(ids, field, attributes) {
    this.editEpoch++
    const keys = ids.map(id => `${id}:${field}`)
    const operation = async () => {
      const changes = ids.map(id => ({ id, version: this.row(id).dataset.version, attributes: attributes(this.row(id)) }))
      operation.changes = changes
      const result = await this.request(this.urlValue, "PATCH", { changes })
      this.finishPending(keys)
      await this.renderStreams(result)
      this.undoHistory.push({ token: result.undo, ids, field })
    }
    this.enqueue(operation, keys)
  }

  enqueue(operation, keys = [], key = keys.join("|") || crypto.randomUUID()) {
    this.supersedeFailures(keys, key)
    operation.keys = keys
    operation.key = key
    operation.settled = false
    keys.forEach(cell => this.pending.set(cell, (this.pending.get(cell) || 0) + 1))
    this.queue.push(operation)
    this.drain()
  }

  supersedeFailures(keys, key) {
    this.failures.delete(key)
    for (const [failedKey, failure] of this.failures) {
      if (!failure.keys.length) continue
      failure.keys = failure.keys.filter(cell => !keys.includes(cell))
      if (!failure.keys.length) this.failures.delete(failedKey)
    }
  }

  async drain() {
    if (this.disconnected || this.busy || !this.queue.length) return
    this.busy = true
    const operation = this.queue.shift()
    this.currentOperation = operation
    this.supersedeFailures(operation.keys, operation.key)
    this.refreshErrors()
    try {
      await operation()
    } catch (error) {
      if (this.disconnected) return
      this.finishPending(operation.keys)
      operation.error = error.message
      operation.details = error.details
      this.failures.set(operation.key, operation)
      this.restoreFailedValues(operation)
    } finally {
      this.finishPending(operation.keys)
      this.busy = false
      this.currentOperation = null
      if (!this.disconnected) {
        this.refreshErrors()
        this.drain()
        this.resumeSearch()
      }
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

  restoreFailedValues(operation) {
    for (const key of operation.keys) {
      if (this.pending.has(key)) continue
      const separator = key.indexOf(":")
      const id = key.slice(0, separator)
      const field = key.slice(separator + 1)
      const row = this.row(id)
      const input = row && this.cell(row, field)?.querySelector("[data-editor]")
      const attributes = operation.changes?.find(change => change.id === id)?.attributes
      if (!input || !attributes || input === document.activeElement) continue
      const value = field.startsWith("metadata:") ? attributes.metadata?.[field.slice(9)] : attributes[field]
      if (value !== undefined) {
        input.value = value ?? ""
        input.dataset.original = input.value
        input.dispatchEvent(new Event("input", { bubbles: true }))
      }
    }
  }

  refreshErrors() {
    for (const [key, target] of [["create", this.draftErrorTarget], ["columns", this.columnsErrorTarget], ["undo", this.undoErrorTarget], ["dialog", this.dialogErrorTarget]]) {
      const failure = this.failures.get(key)
      target.textContent = failure ? `Couldn't save: ${failure.error}` : ""
      target.classList.toggle("hidden", !failure)
    }
    const savedId = this.failures.get("create")?.details?.shot_id
    this.savedShotTarget.classList.toggle("hidden", !savedId)
    if (savedId) this.savedShotTarget.href = `/shots/${encodeURIComponent(savedId)}`
    this.undoTarget.disabled = this.busy || this.queue.length > 0
    this.undoTarget.classList.toggle("hidden!", !this.lastOperation)
    this.undoLabelTarget.textContent = this.lastOperation?.ids.length > 1 ? `Undo change to ${this.lastOperation.ids.length} shots` : "Undo last change"
    this.undoTarget.title = `${this.undoHistory.length} changes available to undo`

    this.rowTargets.forEach(row => {
      const messages = []
      row.querySelectorAll('[aria-invalid="true"]').forEach(input => input.removeAttribute("aria-invalid"))
      row.querySelectorAll("[data-field-error]").forEach(cell => {
        cell.classList.remove("bg-red-50", "dark:bg-red-950", "ring-1", "ring-inset", "ring-red-500")
        delete cell.dataset.fieldError
      })
      for (const failure of this.failures.values()) {
        failure.keys.filter(key => key.startsWith(`${row.dataset.shotId}:`)).forEach(key => {
          const field = key.slice(row.dataset.shotId.length + 1)
          const label = this.columnListTarget.querySelector(`[data-column-choice="${CSS.escape(field)}"] [data-column-label]`)?.textContent || field
          messages.push(`${label}: ${failure.error}`)
          const cell = this.cell(row, field)
          if (cell) {
            cell.dataset.fieldError = "true"
            cell.classList.add("bg-red-50", "dark:bg-red-950")
            cell.querySelector("[data-editor]")?.setAttribute("aria-invalid", "true")
          }
        })
      }
      let errorRow = this.rowsTarget.querySelector(`[data-error-for="${row.dataset.shotId}"]`)
      if (messages.length) {
        if (!errorRow) {
          errorRow = document.createElement("tr")
          errorRow.dataset.errorFor = row.dataset.shotId
          errorRow.className = "bg-red-50 text-sm text-red-700 dark:bg-red-950 dark:text-red-300"
          const cell = document.createElement("td")
          cell.className = "px-3 py-2"
          cell.setAttribute("role", "alert")
          errorRow.append(cell)
          row.after(errorRow)
        }
        errorRow.firstElementChild.colSpan = this.visibleColumnsTarget.children.length + 1
        errorRow.firstElementChild.textContent = `Couldn't save. ${[...new Set(messages)].join(" ")} Edit the value and press Enter to save again.`
      } else {
        errorRow?.remove()
      }
    })
  }

  async request(url, method, body) {
    const response = await fetch(url, {
      method,
      headers: { "Content-Type": "application/json", Accept: "application/json", "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content },
      body: JSON.stringify(body)
    })
    if (response.status === 204) return {}
    const data = await response.json().catch(() => ({}))
    if (!response.ok || response.redirected) {
      const error = new Error(data.error || "Request failed. Reload if your session has expired.")
      error.details = data
      throw error
    }
    return data
  }

  async renderStreams(result) {
    if (this.disconnected || !this.element.isConnected) throw new Error("Page changed before rendering completed")
    if (!result.stream?.trim()) return
    const rendered = new Promise((resolve, reject) => this.pendingRenders.set(result.render_id, { resolve, reject }))
    Turbo.renderStreamMessage(result.stream)
    await rendered
    this.applyColumns()
    this.select()
  }

  beforeMorph(event) {
    const element = event.target
    const incoming = event.detail.newElement
    if (element.matches("[data-shot-id]")) {
      if (incoming?.dataset.journalPartial === "true") this.partialRows.add(element.dataset.shotId)
      return
    }
    if (element.matches("[data-selection]")) event.preventDefault()
    const row = element.closest("[data-shot-id]")
    const cell = element.closest("[data-column]")
    if (!row || !cell) return
    const key = `${row.dataset.shotId}:${cell.dataset.column}`
    const editor = cell.querySelector("[data-editor]")
    const dirty = editor === document.activeElement && editor.value !== editor.dataset.original
    if (element === cell && ((this.partialRows.has(row.dataset.shotId) && incoming?.dataset.unloaded) || this.pending.has(key) || this.failureForCell(key) || dirty)) event.preventDefault()
    if (element.matches("[data-editor]") && element === document.activeElement && element.value !== element.dataset.original) event.preventDefault()
  }

  beforeMorphAttribute(event) {
    if (this.partialRows.has(event.target.dataset.shotId)) event.preventDefault()
  }

  afterMorph(event) {
    if (event.target.matches("[data-shot-id]")) this.partialRows.delete(event.target.dataset.shotId)
    if (event.target.matches("[data-editor]") && event.target === document.activeElement) event.target.dataset.original = event.target.value
  }

  async loadCells(ids, fields) {
    if (!ids.length || !fields.length) return
    for (let offset = 0; offset < ids.length; offset += this.maxBatchValue) {
      const url = new URL(this.cellsUrlValue, window.location.origin)
      ids.slice(offset, offset + this.maxBatchValue).forEach(id => url.searchParams.append("ids[]", id))
      fields.forEach(field => url.searchParams.append("fields[]", field))
      const result = await this.request(url, "GET")
      await this.renderStreams(result)
      if (result.tags && this.tagEditor()) this.tagEditor().tagify.settings.whitelist = result.tags
    }
    this.applyColumns()
  }

  async loadVisibleCells() {
    const fields = [...this.visibleColumnsTarget.children].map(item => item.dataset.columnChoice)
    const ids = this.rowTargets.filter(row => fields.some(field => this.cell(row, field)?.dataset.unloaded)).map(row => row.dataset.shotId)
    const missing = fields.filter(field => ids.some(id => this.cell(this.row(id), field)?.dataset.unloaded))
    await this.loadCells(ids, missing)
  }

  undo() {
    this.performUndo(this.lastOperation)
  }

  undoShortcut(event) {
    if (event.defaultPrevented || !(event.metaKey || event.ctrlKey) || event.altKey || event.shiftKey || event.key.toLowerCase() !== "z") return
    const input = event.target.closest?.("[data-editor]")
    if (input ? input.value !== input.dataset.original : event.target.closest?.("input, textarea, [contenteditable], lexxy-editor")) return
    if (!this.lastOperation || this.busy || this.queue.length || this.dialogTarget.open) return
    event.preventDefault()
    this.undo()
  }

  performUndo(operation) {
    if (!operation) return
    this.editEpoch++
    this.enqueue(async () => {
      const result = await this.request(this.urlValue, "PATCH", { undo: operation.token })
      if (this.lastOperation === operation) {
        this.undoHistory.pop()
      }
      await this.renderStreams(result)
      if (Object.values(this.queryValue).some(Boolean)) this.searchPending = true
    }, [], "undo")
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
      this.selectionNoticeTarget.textContent = "Select shots first"
      return
    }
    this.openDialog(mode, ids)
  }

  openDialog(mode, ids, field = "profile_title") {
    this.dialogLoadVersion++
    this.dialogMode = mode
    this.dialogIds = ids
    this.dialogFormTarget.reset()
    this.resetComboboxes(this.dialogFormTarget)
    this.dialogTarget.classList.toggle("overflow-y-auto", mode !== "tags")
    this.dialogTarget.classList.toggle("overflow-visible", mode === "tags")
    for (const [name, target] of Object.entries({ coffee: this.coffeeFieldsTarget, field: this.fieldFieldsTarget, tags: this.tagFieldsTarget, note: this.noteFieldsTarget })) {
      target.classList.toggle("hidden", name !== mode)
    }
    this.applyTarget.textContent = mode === "note" ? "Save notes" : ids.length === 1 ? "Save" : `Apply to ${ids.length} shots`
    this.dialogTitleTarget.textContent = { coffee: "Assign coffee", field: "Set field", tags: "Tags", note: "Notes" }[mode]
    if (mode === "field") {
      const select = this.dialogFormTarget.elements.field
      ;[...select.options].forEach(option => { option.disabled = ["start_time", "duration"].includes(option.value) && ids.some(id => this.row(id).dataset.manual === "false") })
      select.value = field
      this.fieldChanged()
    }
    if (mode === "tags") {
      this.tagEditor()?.tagify.removeAllTags()
      this.readForDialog(["tag_list"], () => {
        const lists = ids.map(id => (this.cell(this.row(id), "tag_list").dataset.value || "").split(",").filter(Boolean))
        this.tagEditor()?.tagify.addTags(lists[0].filter(tag => lists.every(tags => tags.includes(tag))))
      }, true)
    }
    if (mode === "coffee" && ids.length === 1) {
      const fields = this.coffeeFieldsTarget.querySelector('[name="bean_brand"]') ? ["bean_brand", "bean_type"] : []
      this.readForDialog(fields, () => this.fillCoffee(ids[0]))
    }
    if (!this.dialogTarget.open) this.dialogTarget.showModal()
  }

  fillCoffee(id) {
      const row = this.row(id)
      const attempted = this.failureForCell(`${id}:coffee`)?.changes?.find(change => change.id === id)?.attributes || {}
      for (const name of ["coffee_bag_id", "canonical_coffee_bag_id", "bean_brand", "bean_type"]) {
        const input = this.coffeeFieldsTarget.querySelector(`[name="${name}"]`)
        if (input) {
          input.value = attempted[name] ?? (name === "coffee_bag_id" ? row.dataset.coffeeBagId : name === "canonical_coffee_bag_id" ? row.dataset.canonicalCoffeeBagId : this.cell(row, name)?.dataset.value || "")
          this.combobox(input.closest('[data-controller~="combobox"]'))?.reset(input.value)
        }
      }
      const canonical = this.coffeeFieldsTarget.querySelector('[name="canonical_coffee_bag_id"]')
      const search = this.coffeeFieldsTarget.querySelector('input[type="search"]')
      if (search) search.value = canonical.value ? [this.cell(row, "bean_brand")?.dataset.value, this.cell(row, "bean_type")?.dataset.value].filter(Boolean).join(" / ") : ""
  }

  readForDialog(fields, ready, force = false) {
    const version = ++this.dialogLoadVersion
    const ids = [...this.dialogIds]
    this.dialogFormTarget.inert = true
    this.enqueue(async () => {
      try {
        const missing = fields.filter(field => force || ids.some(id => !this.cell(this.row(id), field) || this.cell(this.row(id), field).dataset.unloaded))
        await this.loadCells(ids, missing)
        if (version === this.dialogLoadVersion) ready()
      } catch (error) {
        if (version === this.dialogLoadVersion) throw error
      } finally {
        if (version === this.dialogLoadVersion) this.dialogFormTarget.inert = false
      }
    }, [], "dialog")
  }

  combobox(element) {
    return element && this.application.getControllerForElementAndIdentifier(element, "combobox")
  }

  resetComboboxes(container) {
    container.querySelectorAll('[data-controller~="combobox"]').forEach(element => this.combobox(element)?.reset())
  }

  tagEditor() {
    const element = this.tagFieldsTarget.querySelector('[data-controller~="tags"]')
    return element && this.application.getControllerForElementAndIdentifier(element, "tags")
  }

  fieldChanged() {
    const field = this.dialogFormTarget.elements.field.value
    const dropdown = this.fieldFieldsTarget.querySelector(`[data-dropdown-field="${CSS.escape(field)}"]`)
    this.fieldFieldsTarget.querySelectorAll("[data-dropdown-field]").forEach(element => element.classList.toggle("hidden", element !== dropdown))
    this.fieldFieldsTarget.querySelector("[data-plain-field]").classList.toggle("hidden", !!dropdown)
    this.readForDialog(this.dialogIds.length === 1 ? [field] : [], () => {
      const row = this.dialogIds.length === 1 && this.row(this.dialogIds[0])
      const value = row ? this.cell(row, field)?.dataset.value || "" : ""
      if (dropdown) this.combobox(dropdown.querySelector('[data-controller~="combobox"]'))?.reset(value)
      const input = this.dialogFormTarget.elements.value
      input.type = field === "start_time" ? "datetime-local" : "text"
      input.step = "1"
      input.value = value
    })
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
      this.coffeeFieldsTarget.querySelectorAll("[data-shot-field]").forEach(input => {
        attributes[input.name] = input.value
      })
      if (attributes.canonical_coffee_bag_id) {
        delete attributes.bean_brand
        delete attributes.bean_type
      }
      this.save(this.dialogIds, "coffee", () => attributes)
    } else if (this.dialogMode === "field") {
      const field = data.get("field")
      const dropdown = this.fieldFieldsTarget.querySelector(`[data-dropdown-field="${CSS.escape(field)}"] [data-combobox-target="input"]`)
      const attributes = this.attributes(field, dropdown ? dropdown.value : data.get("value"))
      if (["bean_brand", "bean_type"].includes(field)) attributes.canonical_coffee_bag_id = ""
      this.save(this.dialogIds, field, () => attributes)
    } else if (this.dialogMode === "tags") {
      const names = (data.get("tags") || "")
        .split(",")
        .map(name =>
          name
            .trim()
            .toLowerCase()
            .replace(/[^\w\s-]/g, "")
            .replace(/\s+/g, " ")
        )
        .filter(Boolean)
      this.save(this.dialogIds, "tag_list", () => ({ tag_list: names }))
    }
    this.closeDialog()
  }

  openNote(row, field) {
    this.openDialog("note", [row.dataset.shotId])
    this.noteField = field
    const attempted = this.failureForCell(`${row.dataset.shotId}:${field}`)?.changes?.find(change => change.id === row.dataset.shotId)?.attributes[field]
    const value = attempted ?? this.cell(row, field).dataset.value
    const editor = this.noteFieldsTarget.querySelector("lexxy-editor")
    editor.value = value
    this.noteValue = value
    this.dialogTitleTarget.textContent = this.columnListTarget.querySelector(`[data-column-choice="${field}"] [data-column-label]`).textContent.trim()
  }

  closeDialog(event) {
    event?.preventDefault()
    this.dialogLoadVersion++
    this.failures.delete("dialog")
    this.dialogFormTarget.inert = false
    this.dialogTarget.close()
    this.dialogMode = null
    this.refreshErrors()
    this.resumeSearch()
  }

  canonicalSearchChanged(event) {
    event.target.closest("[data-coffee-fields]").querySelector('[name="canonical_coffee_bag_id"]').value = ""
  }

  manualCoffeeChanged(event) {
    const fields = event.target.closest("[data-coffee-fields]")
    fields.querySelector('[name="canonical_coffee_bag_id"]').value = ""
    fields.querySelector('input[type="search"]').value = ""
  }

  canonicalCoffeeSelected(event) {
    const fields = event.currentTarget
    fields.querySelector('[name="bean_brand"]').value = event.detail.selected.dataset.roaster || ""
    fields.querySelector('[name="bean_type"]').value = event.detail.selected.dataset.coffeeBag || ""
    fields.querySelectorAll('[data-controller~="combobox"]').forEach(element => {
      const combo = this.combobox(element)
      combo?.reset(combo.inputTarget.value)
    })
  }

  clearCoffee(event) {
    const fields = event.target.closest("[data-coffee-fields]")
    this.combobox(fields.querySelector('[data-controller~="combobox"]'))?.reset()
  }

  compare() {
    const rows = this.selectedRows
    if (rows.length !== 2) return
    if (this.hasUnsavedChanges() && !window.confirm("Changes are still pending. Leave Journal?")) return
    window.location.assign(`/shots/${rows[0].dataset.shotId}/compare/${rows[1].dataset.shotId}`)
  }

  newShot() {
    if (this.draftTarget.classList.contains("hidden")) {
      this.entryId = crypto.randomUUID()
      this.draftFormTarget.reset()
      this.resetComboboxes(this.draftFormTarget)
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
    this.refreshErrors()
    this.drain()
    this.resumeSearch()
  }

  create(event) {
    event.preventDefault()
    if (this.creating) {
      if (this.failures.has("create")) this.enqueue(this.creationOperation, [], "create")
      return
    }
    this.creating = true
    this.editEpoch++
    const entry_id = this.entryId
    this.creationOperation = async () => {
      const shot = Object.fromEntries([...this.draftFormTarget.querySelectorAll("[data-shot-field]")].map(input => [input.name, input.value]))
      if (shot.canonical_coffee_bag_id) {
        delete shot.bean_brand
        delete shot.bean_type
      }
      this.draftFormTarget.inert = true
      let result
      try {
        result = await this.request(this.createUrlValue, "POST", { shot, entry_id, query: this.queryValue })
      } finally {
        this.draftFormTarget.inert = false
      }
      await this.renderStreams(result)
      this.tableViewportTarget.scrollTop = 0
      this.creating = false
      this.creationOperation = null
      this.cancelDraft()
    }
    this.enqueue(this.creationOperation, [], "create")
  }

  deleteShot(event) {
    if (event.defaultPrevented) return
    event.preventDefault()
    const row = event.currentTarget.closest("[data-shot-id]")
    const id = row.dataset.shotId
    const url = event.currentTarget.dataset.deleteUrl
    this.editEpoch++
    this.enqueue(async () => {
      const result = await this.request(url, "DELETE", { query: this.queryValue })
      await this.renderStreams(result)
      this.rowsTarget.querySelector(`[data-error-for="${id}"]`)?.remove()
      const keys = [...this.failures.values()].flatMap(failure => failure.keys.filter(key => key.startsWith(`${id}:`)))
      this.supersedeFailures(keys, "undo")
      this.undoHistory = this.undoHistory.filter(operation => !operation.ids.includes(id))
      this.select()
    }, [`${id}:actions`], `delete:${id}`)
  }

  columns(movedField = null) {
    this.applyColumns(movedField)
    const columns = { order: this.columnItems.map(item => item.dataset.columnChoice), hidden: [...this.hiddenColumnsTarget.children].map(item => item.dataset.columnChoice) }
    cancelAnimationFrame(this.columnSaveFrame)
    this.columnSaveFrame = requestAnimationFrame(() => {
      this.columnSaveFrame = requestAnimationFrame(() => {
        this.columnSaveFrame = null
        this.enqueue(async () => {
          await this.request(this.columnsUrlValue, "PATCH", { columns })
          await this.loadVisibleCells()
        }, [], "columns")
      })
    })
  }

  get columnItems() {
    return [...this.columnListTarget.querySelectorAll("[data-column-choice]")]
  }

  toggleColumns() {
    const hidden = this.columnsPanelTarget.classList.toggle("hidden")
    this.columnsButtonTarget.setAttribute("aria-expanded", String(!hidden))
    if (hidden) this.cancelColumnDrag()
  }

  resetColumns() {
    this.cancelColumnDrag()
    cancelAnimationFrame(this.columnSaveFrame)
    this.columnSaveFrame = null
    this.enqueue(
      async () => {
        const settings = await this.request(this.columnsUrlValue, "PATCH", { columns: null })
        settings.order.forEach(field => {
          const item = this.columnListTarget.querySelector(`[data-column-choice="${CSS.escape(field)}"]`)
          const group = settings.visible.includes(field) ? this.visibleColumnsTarget : this.hiddenColumnsTarget
          group.append(item)
        })
        this.applyColumns()
        await this.loadVisibleCells()
      },
      [],
      "columns"
    )
  }

  startColumnDrag(event) {
    if (event.button !== 0 || !event.isPrimary) return
    event.preventDefault()
    this.draggedColumn = event.currentTarget.closest("[data-column-choice]")
    this.columnGroupsBeforeDrag = [this.visibleColumnsTarget, this.hiddenColumnsTarget].map(group => [group, [...group.children]])
    this.columnPointerId = event.pointerId
    const bounds = this.draggedColumn.getBoundingClientRect()
    this.columnDragOffset = { x: event.clientX - bounds.left, y: event.clientY - bounds.top }
    this.columnDragPreview = this.draggedColumn.cloneNode(true)
    this.columnDragPreview.removeAttribute("data-column-choice")
    this.columnDragPreview.dataset.journalDragPreview = ""
    this.columnDragPreview.classList.add("shadow-lg")
    Object.assign(this.columnDragPreview.style, { position: "fixed", left: "0", top: "0", width: `${bounds.width}px`, height: `${bounds.height}px`, pointerEvents: "none", zIndex: "100" })
    document.body.append(this.columnDragPreview)
    this.moveColumnPreview(event)
    this.draggedColumn.classList.add("opacity-30")
    this.columnListTarget.setPointerCapture(event.pointerId)
  }

  dragColumn(event) {
    if (!this.draggedColumn || event.pointerId !== this.columnPointerId) return
    this.moveColumnPreview(event)
    const hit = document.elementFromPoint(event.clientX, event.clientY)
    const group = hit?.closest("[data-column-visibility]")
    if (!group || !this.columnListTarget.contains(group)) return
    const target = hit.closest("[data-column-choice]")
    if (target === this.draggedColumn) return
    if (!target) {
      group.append(this.draggedColumn)
    } else if (target.parentElement !== this.draggedColumn.parentElement) {
      const bounds = target.getBoundingClientRect()
      if (event.clientX < bounds.left + bounds.width / 2) target.before(this.draggedColumn)
      else target.after(this.draggedColumn)
    } else {
      const items = [...group.children]
      if (items.indexOf(this.draggedColumn) < items.indexOf(target)) target.after(this.draggedColumn)
      else target.before(this.draggedColumn)
    }
  }

  moveColumnPreview(event) {
    this.columnDragPreview.style.transform = `translate(${event.clientX - this.columnDragOffset.x}px, ${event.clientY - this.columnDragOffset.y}px)`
  }

  finishColumnDrag(event) {
    if (!this.draggedColumn || event.pointerId !== this.columnPointerId) return
    const item = this.draggedColumn
    const changed = this.columnGroupsBeforeDrag.some(([group, items]) => group.children.length !== items.length || [...group.children].some((item, index) => item !== items[index]))
    this.endColumnDrag()
    if (changed) this.columns(item.dataset.columnChoice)
    item.querySelector("button").focus()
  }

  cancelColumnDrag(event) {
    if (!this.draggedColumn) return
    event?.preventDefault()
    this.columnGroupsBeforeDrag.forEach(([group, items]) => group.append(...items))
    this.endColumnDrag()
  }

  endColumnDrag() {
    this.draggedColumn.classList.remove("opacity-30")
    this.columnDragPreview.remove()
    this.columnDragPreview = null
    this.draggedColumn = null
    if (this.columnListTarget.hasPointerCapture(this.columnPointerId)) this.columnListTarget.releasePointerCapture(this.columnPointerId)
    this.columnGroupsBeforeDrag = null
    this.columnPointerId = null
  }

  moveColumn(event) {
    const direction = { ArrowLeft: -1, ArrowUp: -1, ArrowRight: 1, ArrowDown: 1 }[event.key]
    if (!direction || this.draggedColumn) return
    event.preventDefault()
    const item = event.currentTarget.closest("[data-column-choice]")
    if (event.key === "ArrowUp" || event.key === "ArrowDown") {
      const group = direction < 0 ? this.visibleColumnsTarget : this.hiddenColumnsTarget
      if (item.parentElement === group) return
      group.append(item)
    } else {
      const neighbor = direction < 0 ? item.previousElementSibling : item.nextElementSibling
      if (!neighbor) return
      if (direction < 0) neighbor.before(item)
      else neighbor.after(item)
    }
    this.columns(item.dataset.columnChoice)
    event.currentTarget.focus()
  }

  applyColumns(movedField = null) {
    const choices = this.columnItems
    this.tableTarget.querySelectorAll("tr").forEach(row => this.arrangeColumns(row, choices, movedField))
  }

  rowTargetConnected(row) {
    if (!this.hasColumnListTarget) return
    this.arrangeColumns(row, this.columnItems)
  }

  arrangeColumns(row, choices, movedField = null) {
    const cells = new Map([...row.querySelectorAll("[data-column]")].map(cell => [cell.dataset.column, cell]))
    const known = new Set(choices.map(item => item.dataset.columnChoice))
    cells.forEach((cell, field) => { if (!known.has(field)) cell.classList.add("hidden") })
    let previous = row.firstElementChild
    choices.forEach(item => {
      const field = item.dataset.columnChoice
      const cell = cells.get(field)
      if (!cell) return
      if (!movedField || movedField === field) {
        cell.classList.toggle("hidden", item.parentElement === this.hiddenColumnsTarget)
        if (previous.nextElementSibling !== cell) previous.after(cell)
      }
      previous = cell
    })
  }

  beforeStream(event) {
    const stream = event.target
    const renderId = stream.dataset.journalRenderId
    if (renderId && this.pendingRenders.has(renderId)) {
      const render = event.detail.render
      event.detail.render = async element => {
        try {
          if (!this.disconnected) await render(element)
          if (stream.dataset.journalFinal === "true") {
            this.pendingRenders.get(renderId)?.resolve()
            this.pendingRenders.delete(renderId)
          }
        } catch (error) {
          this.pendingRenders.get(renderId)?.reject(error)
          this.pendingRenders.delete(renderId)
        }
      }
    }
    const searchId = stream.dataset.journalSearchId
    if (searchId && searchId !== this.searchIdValue) {
      event.preventDefault()
      return
    }
    if (stream.dataset.journalFreshSearch === "true" && this.acceptedSearchId !== searchId) {
      if (this.searchBlocked || this.searchEpoch !== this.editEpoch || this.hasUnsavedChanges() || this.rowsTarget.querySelector("[data-editor]:focus")) {
        event.preventDefault()
        this.searchBlocked = true
        this.searchPending = true
        this.showSearchNotice("Search paused while you finish editing.")
        this.resumeSearch()
        return
      }
      this.acceptedSearchId = searchId
      this.queryValue = this.pendingQuery || this.queryValue
      this.showSearchNotice("")
    }
    if (stream.getAttribute("target") !== "journal-rows") return
    if (stream.getAttribute("action") === "update") {
      this.tableViewportTarget.scrollTop = 0
      this.selectionTarget.textContent = "0 selected"
      this.selectionNoticeTarget.textContent = ""
      this.bulkBarTarget.classList.add("hidden")
      this.bulkBarTarget.classList.remove("flex")
      this.tableTarget.querySelector("thead input[type=checkbox]").checked = false
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
      if (!this.hasUnsavedChanges() && !this.rowsTarget.querySelector("[data-editor]:focus")) {
        this.searchPending = false
        this.searchTarget.requestSubmit()
      } else {
        this.showSearchNotice("Search paused while you finish editing.")
      }
    }, 300)
  }

  resumeSearch() {
    if (this.searchPending && !this.hasUnsavedChanges() && !this.rowsTarget.querySelector("[data-editor]:focus")) this.search()
  }

  showSearchNotice(message) {
    this.searchNoticeTarget.textContent = message
    this.searchNoticeTarget.classList.toggle("hidden", !message)
  }

  hasUnsavedChanges() {
    const editing = this.rowsTarget.querySelector("[data-editor]:focus")
    const dirtyCell = editing && editing.value !== editing.dataset.original
    const dirtyNote = this.dialogMode === "note" && this.noteFieldsTarget.querySelector("lexxy-editor").value !== this.noteValue
    return !!this.columnSaveFrame || this.busy || this.queue.length > 0 || this.failures.size > 0 || !this.draftTarget.classList.contains("hidden") || this.dialogTarget.open || dirtyCell || dirtyNote
  }

  beforeVisit(event) {
    if (this.hasUnsavedChanges() && !window.confirm("Unsaved changes will be lost. Leave Journal?")) event.preventDefault()
  }

  beforeSubmit(event) {
    if (event.target !== this.searchTarget) return
    if (this.hasUnsavedChanges()) {
      event.preventDefault()
      this.showSearchNotice("Finish or cancel pending edits before searching.")
      this.searchPending = true
    } else {
      this.searchIdValue = crypto.randomUUID()
      this.searchTarget.elements.journal_search_id.value = this.searchIdValue
      this.searchEpoch = this.editEpoch
      this.searchBlocked = false
      this.acceptedSearchId = null
      this.pendingQuery = { q: this.searchTarget.elements.q.value }
      this.showSearchNotice("")
    }
  }

  beforeUnload(event) {
    if (!this.hasUnsavedChanges()) return
    event.preventDefault()
    event.returnValue = ""
  }
}
