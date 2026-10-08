import assert from "node:assert/strict"
import { registerHooks } from "node:module"
import { test } from "node:test"

registerHooks({
  resolve(specifier, context, next) {
    const stubs = {
      "@hotwired/stimulus": "export class Controller {}",
      "@hotwired/turbo-rails": "export const Turbo = { visit: url => globalThis.uploadTest.visits.push(url) }",
      "@rails/request.js": "export const post = (url, options) => globalThis.uploadTest.post(url, options)",
      "controllers/application": "export const appsignal = { sendError: error => { throw error } }"
    }
    if (Object.hasOwn(stubs, specifier)) return { url: `data:text/javascript,${encodeURIComponent(stubs[specifier])}`, shortCircuit: true }
    return next(specifier, context)
  }
})
const { default: Upload } = await import("../../app/javascript/controllers/upload_controller.js")

async function upload(fileCount, statuses = []) {
  const result = { batches: [], visits: [], errors: [] }
  globalThis.uploadTest = {
    visits: result.visits,
    post: async (url, { body }) => {
      assert.equal(url, "/shots?drag=1")
      result.batches.push(body.getAll("files[]").length)
      const status = statuses.shift() ?? 200
      return { ok: status < 300, unprocessableEntity: status === 422 }
    }
  }
  globalThis.document = { getElementById: () => ({ insertAdjacentHTML: (_, html) => result.errors.push(html) }) }
  const classList = { add() {}, remove() {} }
  const controller = Object.assign(new Upload(), {
    dropAreaTarget: { classList },
    loaderTarget: { classList },
    formTarget: { action: "/shots" },
    errorTarget: { innerHTML: "error" }
  })
  await controller.upload(Array.from({ length: fileCount }, (_, i) => `${i}.shot`))
  delete globalThis.document
  return result
}

test("uploads files in batches and stops at the first failed batch", async () => {
  assert.deepEqual(await upload(120), { batches: [50, 50, 20], visits: ["/shots"], errors: [] })
  assert.deepEqual(await upload(120, [422]), { batches: [50], visits: ["/shots"], errors: [] })
  assert.deepEqual(await upload(120, [200, 500]), { batches: [50, 50], visits: [], errors: ["error"] })
  assert.deepEqual(await upload(0), { batches: [], visits: [], errors: [] })
})
