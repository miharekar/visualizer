import assert from "node:assert/strict"
import { execFile } from "node:child_process"
import { randomUUID } from "node:crypto"
import { createRequire } from "node:module"
import { fileURLToPath } from "node:url"
import { promisify } from "node:util"
import test from "node:test"

const { chromium } = createRequire(import.meta.url)(process.env.PLAYWRIGHT_MODULE || "playwright")
const baseURL = process.env.JOURNAL_BROWSER_URL || "http://localhost:3000"
const env = {
  ...process.env,
  RAILS_ENV: process.env.RAILS_ENV || "development",
  JOURNAL_BROWSER_EMAIL: process.env.JOURNAL_BROWSER_EMAIL || `journal-browser-${randomUUID()}@example.invalid`,
  JOURNAL_BROWSER_PASSWORD: process.env.JOURNAL_BROWSER_PASSWORD || randomUUID()
}
const fixture = mode =>
  promisify(execFile)("bin/rails", ["runner", "test/browser/fixture.rb", mode], {
    cwd: fileURLToPath(new URL("../../", import.meta.url)),
    env,
    timeout: 60000
  })

test("journal browser regressions", { timeout: 180000 }, async t => {
  await fixture("setup")
  t.diagnostic(`Fixture: ${env.JOURNAL_BROWSER_EMAIL}`)
  let browser
  try {
    browser = await chromium.launch()
    const page = await browser.newPage({
      baseURL,
      viewport: { width: 1440, height: 1000 }
    })
    page.setDefaultTimeout(8000)
    // Keep Turbo's native fetch/events. Delay only reading a stream body,
    // exposing the gap between response headers/submit-end and replacement.
    await page.addInitScript(() => {
      const text = Response.prototype.text
      Response.prototype.text = async function () {
        const body = await text.call(this)
        const selectedResponse = window.holdJournalBody === "pagination" ? this.url.includes("before=") : new URL(this.url).pathname === "/shots/journal"
        if (window.holdJournalBody && selectedResponse && this.headers.get("content-type")?.includes("turbo-stream")) {
          window.holdJournalBody = false
          await new Promise(resolve => {
            window.releaseJournalBody = resolve
          })
        }
        return body
      }
      document.addEventListener("turbo:submit-end", () => {
        window.journalSubmitEnded = true
      })
      window.journalRenderedTargets = []
      document.addEventListener("turbo:before-stream-render", event => {
        const render = event.detail.render
        event.detail.render = async stream => {
          await render(stream)
          window.journalRenderedTargets.push(stream.target)
        }
      })
    })
    await page.goto("/session/new")
    await page.locator("#email").fill(env.JOURNAL_BROWSER_EMAIL)
    await page.locator("#password").fill(env.JOURNAL_BROWSER_PASSWORD)
    await Promise.all([page.waitForURL(url => !url.pathname.includes("session/new")), page.getByRole("button", { name: "Sign in", exact: true }).click()])

    const ratings = page.locator('td[data-column="espresso_enjoyment"] input[type="number"]')
    const dialog = page.locator("#journal-editor dialog")
    const search = page.locator('input[name="q"]')
    const holdBody = (kind = "journal") =>
      page.evaluate(kind => {
        window.holdJournalBody = kind
        window.journalSubmitEnded = false
        window.releaseJournalBody = null
      }, kind)
    const bodyHeld = () => page.waitForFunction(() => window.releaseJournalBody && window.journalSubmitEnded)
    const releaseBody = () => page.evaluate(() => window.releaseJournalBody?.())
    const check = async (name, fn) => {
      await t.test(name, async () => {
        await page.goto("/shots")
        await ratings.first().waitFor()
        try {
          await fn()
        } catch (error) {
          t.diagnostic(
            JSON.stringify(
              await page.evaluate(() => ({
                url: location.href,
                rows: document.querySelectorAll("tbody tr").length,
                saving: document.querySelectorAll("[data-saving]").length,
                unsaved: document.querySelectorAll("[data-unsaved]").length,
                query: document.querySelector('input[name="q"]')?.value
              }))
            )
          )
          throw error
        } finally {
          await releaseBody()
          await page.unrouteAll({ behavior: "wait" })
        }
      })
    }

    await check("pending cell stays readonly; Enter/blur submits once; search waits", async () => {
      let saves = 0
      let searches = 0
      await page.route("**/journal", async route => {
        saves++
        await route.continue()
      })
      await page.route("**/shots?*", async route => {
        searches++
        await route.continue()
      })
      await holdBody()
      const oldInput = await ratings.first().elementHandle()
      await ratings.first().fill("81")
      await ratings.first().press("Enter")
      await bodyHeld()
      assert.equal(await oldInput.evaluate(el => el.readOnly), true, "cell unlocked before stream replacement")
      assert.equal(await oldInput.evaluate(el => el.form.hasAttribute("data-saving")), true, "pending form lost data-saving")
      await page.getByRole("button", { name: "Columns", exact: true }).click()
      const panel = page.locator("#journal-columns-panel")
      await panel.getByRole("button", { name: "Apply", exact: true }).click()
      await panel.getByText("Wait for pending saves or search to finish, then Apply.").waitFor()
      assert.equal(await oldInput.evaluate(el => el.isConnected), true)
      await panel.getByRole("button", { name: "Cancel", exact: true }).click()
      await search.fill("Browser Journal 0")
      // Longer than search debounce: prove no request while save is pending.
      await page.waitForTimeout(1200)
      assert.equal(searches, 0)
      assert.equal(saves, 1, "Enter plus native change/blur duplicated save")
      await releaseBody()
      await page.waitForFunction(el => !el.isConnected, oldInput)
      try {
        // Search terms are substrings: 0 also matches fixture rows 10, 20, 30.
        await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 4)
      } finally {
        t.diagnostic(`Pending search: ${saves} saves, ${searches} searches`)
      }
      assert.equal(searches, 1, "queued search must resume exactly once")
      assert.equal(await ratings.first().inputValue(), "81")
      await page.reload()
      assert.equal(await ratings.first().inputValue(), "81")
    })

    await check("overlapping cell saves preserve neighboring values when responses reverse", async () => {
      const row = page.locator("tbody tr").first()
      const dose = row.locator('td[data-column="bean_weight"] input[name="value"]')
      const yieldInput = row.locator('td[data-column="drink_weight"] input[name="value"]')
      await holdBody()
      const oldDose = await dose.elementHandle()
      await dose.fill("20")
      await dose.press("Enter")
      await bodyHeld()
      const oldYield = await yieldInput.elementHandle()
      await yieldInput.fill("42")
      await yieldInput.press("Enter")
      await page.waitForFunction(el => !el.isConnected, oldYield)
      assert.equal(await oldDose.evaluate(el => el.isConnected && el.readOnly), true)
      await releaseBody()
      await page.waitForFunction(el => !el.isConnected, oldDose)
      assert.equal(await dose.inputValue(), "20")
      assert.equal(await yieldInput.inputValue(), "42")
      await page.reload()
      assert.equal(await dose.inputValue(), "20")
      assert.equal(await yieldInput.inputValue(), "42")
    })

    await check("stale pagination body cannot append into newer search results", async () => {
      const oldRows = await page.locator("tbody").getAttribute("id")
      await holdBody("pagination")
      await page.locator("#journal-results > div.relative.overflow-auto").evaluate(el => (el.scrollTop = el.scrollHeight))
      await page.waitForFunction(() => window.releaseJournalBody)
      await search.fill("Browser Journal 34")
      await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 1)
      const newRows = await page.locator("tbody").getAttribute("id")
      assert.notEqual(newRows, oldRows)
      await releaseBody()
      await page.waitForFunction(target => window.journalRenderedTargets.includes(target), oldRows)
      assert.equal(await page.locator("tbody tr").count(), 1)
      assert.equal(await page.locator('td[data-column="profile_title"] input[name="value"]').inputValue(), "Browser Journal 34")
    })

    await check("searches serialize and keep results inert until latest query renders", async () => {
      const queries = []
      const releases = []
      const gates = [0, 1].map(() => new Promise(resolve => releases.push(resolve)))
      const results = page.locator("#journal-results")
      const profiles = page.locator('td[data-column="profile_title"] input[name="value"]')
      await page.route("**/shots?*", async route => {
        assert.equal(route.request().method(), "GET")
        queries.push(new URL(route.request().url()).searchParams.get("q"))
        await gates[queries.length - 1]
        await route.continue()
      })
      try {
        const first = page.waitForRequest(req => new URL(req.url()).searchParams.get("q") === "Browser Journal 34")
        await search.fill("Browser Journal 34")
        await first
        await search.fill("Browser Journal 33")
        // Let the latest query's debounce expire while the first GET is held.
        await page.waitForTimeout(1200)
        assert.deepEqual(queries, ["Browser Journal 34"], "overlapping search request")
        assert.equal(await results.evaluate(el => el.inert), true)
        await page.getByRole("button", { name: "Columns", exact: true }).click()
        const panel = page.locator("#journal-columns-panel")
        await panel.getByRole("button", { name: "Apply", exact: true }).click()
        await panel.getByText("Wait for pending saves or search to finish, then Apply.").waitFor()
        await panel.getByRole("button", { name: "Cancel", exact: true }).click()
        const second = page.waitForRequest(req => new URL(req.url()).searchParams.get("q") === "Browser Journal 33")
        releases[0]()
        await second
        await page.waitForFunction(() => document.querySelector('td[data-column="profile_title"] input[name="value"]')?.value === "Browser Journal 34")
        assert.equal(await results.evaluate(el => el.inert), true, "first render unlocked results while latest search is pending")
        assert.deepEqual(queries, ["Browser Journal 34", "Browser Journal 33"])
        releases[1]()
        await page.waitForFunction(() => {
          const results = document.querySelector("#journal-results")
          const profile = results.querySelector('td[data-column="profile_title"] input[name="value"]')
          return !results.inert && profile?.value === "Browser Journal 33"
        })
        assert.equal(await page.locator("tbody tr").count(), 1)
        assert.equal(await profiles.first().inputValue(), "Browser Journal 33")
        assert.equal(await ratings.first().isEditable(), true)
        await ratings.first().focus()
        assert.equal(await ratings.first().evaluate(el => el === document.activeElement), true)
        assert.deepEqual(queries, ["Browser Journal 34", "Browser Journal 33"])
      } finally {
        releases.forEach(release => release())
      }
    })

    await check("transport failure retains value; search requires discard consent", async () => {
      await page.route("**/journal", route => route.abort("failed"))
      await ratings.first().fill("87")
      await ratings.first().press("Enter")
      await page.getByText("Not saved. Press Enter to retry.", { exact: true }).waitFor()
      assert.equal(await ratings.first().inputValue(), "87")
      assert.equal(await ratings.first().evaluate(el => el.readOnly), false)
      assert.equal(await ratings.first().evaluate(el => el.form.hasAttribute("data-unsaved")), true, "failed value must mark form data-unsaved")
      await page.getByRole("button", { name: "Columns", exact: true }).click()
      const panel = page.locator("#journal-columns-panel")
      const keepEdit = page.waitForEvent("dialog").then(prompt => prompt.dismiss())
      await panel.getByRole("button", { name: "Apply", exact: true }).click()
      await keepEdit
      assert.equal(await ratings.first().inputValue(), "87")
      assert.equal(await panel.isVisible(), true)
      await panel.getByRole("button", { name: "Cancel", exact: true }).click()
      const declined = page.waitForEvent("dialog").then(async prompt => {
        assert.equal(prompt.type(), "confirm")
        await prompt.dismiss()
      })
      await search.fill("Browser Journal 34")
      await declined
      assert.equal(await ratings.first().inputValue(), "87")
      assert.ok((await page.locator("tbody tr").count()) > 1)
      const accepted = page.waitForEvent("dialog").then(prompt => prompt.accept())
      await search.fill("Browser Journal 33")
      await accepted
      await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 1)
      assert.equal(await ratings.first().inputValue(), "50")
    })

    await check("server 422 preserves attempted input and focus without stealing newer focus", async () => {
      await page.locator("#journal-results > div.relative.overflow-auto").evaluate(el => (el.scrollTop = el.scrollHeight))
      await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 35)
      for (const last of [true, false]) {
        await page.route("**/journal", route => {
          const body = new URLSearchParams(route.request().postData())
          body.set("value", "101")
          return route.continue({ postData: body.toString() })
        })
        const input = page.locator(`#${await (last ? ratings.last() : ratings.first()).getAttribute("id")}`)
        const oldInput = await input.elementHandle()
        await holdBody()
        await input.fill("60")
        await input.press("Enter")
        await bodyHeld()
        const expectedFocus = await (last ? input : ratings.nth(1)).getAttribute("id")
        await releaseBody()
        await page.waitForFunction(el => !el.isConnected, oldInput)
        await page.waitForFunction(id => document.activeElement?.id === id, expectedFocus)
        assert.equal(await input.inputValue(), "101")
        assert.equal(await input.evaluate(el => el.readOnly), false)
        await input.locator("xpath=ancestor::td").getByText("Espresso enjoyment must be less than or equal to 100").waitFor()
        await page.unrouteAll({ behavior: "wait" })
        const failedInput = await input.elementHandle()
        await input.fill("70")
        await input.press("Enter")
        await page.waitForFunction(el => !el.isConnected, failedInput)
        assert.equal(await input.inputValue(), "70")
      }
    })

    await check("coffee popup saves; pending Save blocks Cancel and Escape", async () => {
      await page.locator('td[data-column="coffee"] a').first().click()
      await dialog.waitFor()
      await page.locator("#journal-coffee-bag").fill("Browser Managed")
      await dialog.locator("li").filter({ hasText: "Browser Managed Coffee" }).click()
      await holdBody()
      await dialog.getByRole("button", { name: "Save", exact: true }).click()
      await bodyHeld()
      assert.equal(await dialog.getByRole("button", { name: "Cancel", exact: true }).isDisabled(), true, "Cancel enabled before stream replacement")
      assert.equal(await page.locator("#journal-coffee-bag").isDisabled(), true)
      await page.keyboard.press("Escape")
      assert.equal(await dialog.evaluate(el => el.open), true)
      await releaseBody()
      await dialog.waitFor({ state: "detached" })
      await page.reload()
      assert.match(await page.locator('td[data-column="coffee"]').first().innerText(), /Browser Managed Coffee/)
    })

    await check("tag dropdown selectable inside modal; transport failure unlocks editor", async () => {
      await page.locator('[data-journal-selection-target="checkbox"]').first().check()
      await page.locator("#journal-bulk-field").selectOption("tag_list")
      await page.getByRole("button", { name: "Set field", exact: true }).click()
      await dialog.locator(".tagify__input").fill("browser")
      await dialog.locator(".tagify__dropdown__item").filter({ hasText: "browser-tag" }).click()
      assert.equal(await page.locator("#journal-editor-value").inputValue(), "browser-tag")
      await page.route("**/journal", route => route.abort("failed"))
      await dialog.getByRole("button", { name: "Save", exact: true }).click()
      await page.waitForFunction(() => {
        const save = document.querySelector('#journal-editor input[type="submit"]')
        return window.journalSubmitEnded && save && !save.matches(":disabled")
      })
      assert.equal(await dialog.getByRole("button", { name: "Cancel", exact: true }).isDisabled(), false)
      assert.equal(await page.locator("#journal-editor-value").inputValue(), "browser-tag")
      await page.unrouteAll({ behavior: "wait" })
      await dialog.getByRole("button", { name: "Save", exact: true }).click()
      await dialog.waitFor({ state: "detached" })
      await search.fill("browser-tag")
      await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 2)
    })

    await check("native column dragging; Apply persists; Reset and Cancel remain staged", async () => {
      const panel = page.locator("#journal-columns-panel")
      const duration = page.locator('td[data-column="duration"]')
      const open = () => page.getByRole("button", { name: "Columns", exact: true }).click()
      const dragDuration = async () => {
        const handle = panel.locator('[data-column="duration"] [draggable="true"]')
        const from = await handle.boundingBox()
        const to = await panel.locator('[data-hidden="true"]').boundingBox()
        await page.mouse.move(from.x + 10, from.y + 10)
        await page.mouse.down()
        await page.mouse.move(to.x + to.width - 4, to.y + to.height - 4, { steps: 5 })
        assert.equal(await page.locator('[data-upload-drop-target="overlay"]').isVisible(), false)
        assert.equal(await handle.isVisible(), true)
        await page.mouse.up()
        assert.equal(await panel.locator('[data-hidden="true"] [data-column="duration"]').count(), 1)
      }
      await open()
      await dragDuration()
      assert.ok((await duration.count()) > 0)
      await panel.getByRole("button", { name: "Cancel", exact: true }).click()
      await open()
      assert.equal(await panel.locator('[data-hidden="false"] [data-column="duration"]').count(), 1)
      await dragDuration()
      await panel.getByRole("button", { name: "Apply", exact: true }).click()
      await duration.first().waitFor({ state: "detached" })
      await page.reload()
      assert.equal(await duration.count(), 0)
      await open()
      await panel.getByRole("button", { name: "Reset to defaults", exact: true }).click()
      assert.equal(await duration.count(), 0)
      await panel.getByRole("button", { name: "Cancel", exact: true }).click()
      await page.reload()
      assert.equal(await duration.count(), 0)
      await open()
      await panel.getByRole("button", { name: "Reset to defaults", exact: true }).click()
      await panel.getByRole("button", { name: "Apply", exact: true }).click()
      await duration.first().waitFor()
    })

    await check("pending columns Apply blocks Cancel and retains search", async () => {
      await search.fill("Browser Journal 34")
      await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 1)
      await page.getByRole("button", { name: "Columns", exact: true }).click()
      const panel = page.locator("#journal-columns-panel")
      const cancel = panel.getByRole("button", { name: "Cancel", exact: true })
      const point = await cancel.boundingBox()
      let release
      const held = new Promise(resolve => {
        release = resolve
      })
      const action = await panel.locator("form").getAttribute("action")
      await page.route(`**${action}`, async route => {
        await held
        await route.continue()
      })
      try {
        const request = page.waitForRequest(req => new URL(req.url()).pathname === action && req.method() !== "GET")
        await panel.getByRole("button", { name: "Apply", exact: true }).click()
        await request
        assert.equal(await cancel.isDisabled(), true, "Cancel enabled during pending columns Apply")
        assert.equal(await panel.locator("fieldset").evaluate(el => el.inert), true)
        await page.mouse.click(point.x + point.width / 2, point.y + point.height / 2)
        await page.getByRole("button", { name: "Columns", exact: true }).click()
        assert.equal(await panel.isVisible(), true, "pending panel dismissed")
      } finally {
        release()
      }
      await panel.waitFor({ state: "hidden" })
      assert.equal(await search.inputValue(), "Browser Journal 34")
      assert.equal(await page.locator("tbody tr").count(), 1)
      await page.reload()
      assert.equal(await search.inputValue(), "Browser Journal 34")
      assert.equal(await page.locator("tbody tr").count(), 1)
    })

    await check("invalid Enter retains focus and does not submit", async () => {
      let saves = 0
      await page.route("**/journal", async route => {
        saves++
        await route.continue()
      })
      await ratings.first().fill("101")
      await ratings.first().press("Enter")
      assert.equal(await ratings.first().evaluate(el => el === document.activeElement), true)
      assert.equal(await ratings.first().evaluate(el => el.validity.rangeOverflow), true)
      assert.equal(await ratings.first().inputValue(), "101")
      assert.equal(await ratings.first().evaluate(el => el.readOnly || el.form.hasAttribute("data-saving")), false)
      assert.equal(saves, 0)
      await ratings.first().fill("70")
      const duration = page.locator('td[data-column="duration"] input[name="value"]').first()
      await duration.fill("-1")
      await duration.press("Enter")
      assert.equal(await duration.evaluate(el => el === document.activeElement && el.validity.rangeUnderflow), true)
      await duration.fill("30")
      await duration.press("Enter")
      await page.waitForFunction(() => !document.querySelector("[data-saving]"))
      await page.locator('[data-journal-selection-target="checkbox"]').first().check()
      await page.locator("#journal-bulk-field").selectOption("acidity")
      await page.getByRole("button", { name: "Set field", exact: true }).click()
      await dialog.locator('input[name="value"]').fill("16")
      const before = saves
      await dialog.getByRole("button", { name: "Save", exact: true }).click()
      assert.equal(await dialog.locator('input[name="value"]').evaluate(el => el.validity.rangeOverflow), true)
      assert.equal(saves, before)
      await dialog.getByRole("button", { name: "Cancel", exact: true }).click()
    })

    await check("notes remain searchable after popup save and manual form creates a shot", async () => {
      await page.locator('[data-journal-selection-target="checkbox"]').first().check()
      await page.locator("#journal-bulk-field").selectOption("espresso_notes")
      await page.getByRole("button", { name: "Set field", exact: true }).click()
      await dialog.locator('lexxy-editor [contenteditable="true"]').fill("Peach browser tasting")
      await dialog.getByRole("button", { name: "Save", exact: true }).click()
      await dialog.waitFor({ state: "detached" })
      await search.fill("Peach browser tasting")
      await page.waitForFunction(() => document.querySelectorAll("tbody tr").length === 1)
      await page.reload()
      assert.equal(await page.locator("tbody tr").count(), 1)
      await page.getByRole("link", { name: "Create", exact: true }).click()
      await page.locator('input[name="shot[profile_title]"]').fill("Browser Manual Creation")
      await page.locator('input[name="shot[duration]"]').fill("32.5")
      await page.getByRole("button", { name: "Save", exact: true }).click()
      await page.waitForURL(/\/shots\/[0-9a-f-]+$/)
      await page.goto("/shots?q=Browser+Manual+Creation")
      assert.equal(await page.locator("tbody tr").count(), 1)
      assert.equal(await page.locator('td[data-column="duration"] input[name="value"]').inputValue(), "32.5")
    })

    await check("confirmation Cancel activated by native Enter does not delete", async () => {
      let deletes = 0
      await page.route("**/shots/*", async route => {
        const request = route.request()
        if (request.method() === "DELETE" || request.postData()?.includes("_method=delete")) deletes++
        await route.continue()
      })
      const row = page.locator("tbody tr").first()
      const rowId = await row.getAttribute("id")
      await row.getByRole("button", { name: "Delete shot", exact: true }).click()
      const cancel = page.locator('[data-action="click->modal#hide"]')
      await cancel.waitFor()
      await cancel.focus()
      await page.keyboard.press("Enter")
      await cancel.waitFor({ state: "hidden" })
      assert.equal(deletes, 0, "Enter on Cancel submitted deletion")
      await page.reload()
      assert.equal(await page.locator("tbody tr").first().getAttribute("id"), rowId)
    })

    await check("selection toolbar stays inside desktop and narrow viewports", async () => {
      for (const width of [1440, 390]) {
        await page.setViewportSize({ width, height: 844 })
        await page.locator('[data-journal-selection-target="checkbox"]').first().check()
        const toolbar = page.locator('[data-journal-selection-target="toolbar"]')
        await toolbar.waitFor()
        const box = await toolbar.boundingBox()
        assert.ok(box.x >= 0 && box.x + box.width <= width, `toolbar overflows ${width}px`)
        assert.ok(box.y >= 0 && box.y + box.height <= 844)
        assert.equal(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), true)
        await toolbar.getByRole("button", { name: "Clear selection", exact: true }).click()
        await toolbar.waitFor({ state: "hidden" })
      }
    })

    await check("Enter from the delete trigger confirms exactly once", async () => {
      await page.setViewportSize({ width: 1440, height: 1000 })
      let deletes = 0
      await page.route("**/shots/*", async route => {
        const request = route.request()
        if (request.method() === "DELETE" || request.postData()?.includes("_method=delete")) deletes++
        await route.continue()
      })
      const row = page.locator("tbody tr").first()
      await row.getByRole("button", { name: "Delete shot", exact: true }).click()
      const rowId = await row.getAttribute("id")
      await page.locator('[data-action="click->modal#hide"]').waitFor()
      await page.keyboard.press("Enter")
      await page.locator(`#${rowId}`).waitFor({ state: "detached" })
      assert.equal(deletes, 1)
    })
  } finally {
    try {
      await browser?.close()
    } finally {
      await fixture("cleanup")
    }
  }
})
