# Journal Browser Regression

Standalone Node test runner + externally installed Playwright. No project/runtime
dependencies, no Rails fixtures, not included in `test/javascript/*_test.mjs`.
Requires Node 22.15+, installed Rails dependencies/database, and running app whose
Rails environment/database matches the runner. Never run against production.

Install browser tooling outside this repository (once):

```sh
npm install --prefix /tmp/visualizer-browser playwright
/tmp/visualizer-browser/node_modules/.bin/playwright install chromium
```

With development app running (`bin/dev`), from repository root:

```sh
PLAYWRIGHT_MODULE=/tmp/visualizer-browser/node_modules/playwright \
  node --test test/browser/journal_test.mjs
```

`PLAYWRIGHT_MODULE` accepts an absolute module directory or entrypoint. Defaults to
normal Node resolution of `playwright`. `JOURNAL_BROWSER_URL` defaults to
`http://localhost:3000`; `RAILS_ENV` defaults to `development`. For isolated CI,
prepare the test database, start Rails with `RAILS_ENV=test`, and run this command
with `RAILS_ENV=test` and matching URL. Workflow/server ownership stays outside
this harness.

Each run creates a random `journal-browser-<UUID>@example.invalid` account and
password, 35 shots, one coffee bag/roaster, and one tag. Setup rejects existing
accounts; cleanup only targets that exact email plus fixture-name marker, never
prefix-deletes accounts. Both Ruby modes refuse environments other than test or
development. Setup is transactional; cleanup runs in `finally`, including failed
assertions/browser startup. Fixture jobs are not enqueued.

Optional `JOURNAL_BROWSER_EMAIL` (must match generated email format) and
`JOURNAL_BROWSER_PASSWORD` provide reproducible dedicated credentials. These must
not identify an existing user. Interrupted/killed processes can leave fixtures;
the test prints its email for manual cleanup:

```sh
JOURNAL_BROWSER_EMAIL=journal-browser-REPLACE-WITH-UUID@example.invalid \
  bin/rails runner test/browser/fixture.rb cleanup
```

Checks run sequentially in one browser session with separate Node subtest results:
native Turbo pending-cell replacement, Enter/change/blur duplication, search
deferral, serialized latest-query searches with inert results, failed-value discard
confirmation, coffee/tag popups, pending-dialog
dismissal and transport retry, staged column preferences/drag ghost, pending columns
Apply dismissal/filter retention, invalid Enter focus, confirmation Cancel via
native Enter, and selection toolbar geometry at desktop/390px widths. Delayed-body checks hold
`Response.text()` after headers arrive, without dispatching synthetic Turbo events
or replacing controllers. Columns Apply holds its request before delivery because
that endpoint redirects to HTML rather than returning a Turbo stream.
Explicit waits exceed search debounce to assert no
premature request; other waits observe events or DOM state. Narrow viewport check
is Chromium layout coverage, not real mobile Safari/touch coverage.
