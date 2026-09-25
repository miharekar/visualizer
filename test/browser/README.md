# Journal Browser Regression

Standalone Node test runner + externally installed Playwright. No project/runtime
dependencies, no Rails fixtures, not included in `test/javascript/*_test.mjs`.
Requires Node 22.15+, installed Rails dependencies/database, and running app whose
Rails environment/database matches the runner. Never run against production.

Install browser tooling outside this repository (once):

```sh
npm install --prefix /tmp/visualizer-browser playwright@1.63.0
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
with `RAILS_ENV=test` and matching URL. GitHub Actions runs this suite in its own
job alongside Rails/native JS tests, builds Tailwind, and starts a test-environment
Rails server.

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
native Turbo pending-cell replacement, overlapping saves, stale pagination,
server 422 values/focus, Enter/change/blur duplication, search deferral,
serialized latest-query searches with inert results, failed-value discard
confirmation for search and columns Apply, coffee/tag popups, backdrop clicks and
pending-dialog dismissal, transport retry, mouse and emulated-touch column dragging without upload-overlay interference,
pull to refresh from the header, search field, or table top, but not while the table is scrolled,
swiping sideways, dragging columns, or editing,
open-panel button styling, pending columns
Apply dismissal/filter retention, numeric bounds, unchanged-cell Enter and Shift+Enter
navigation, notes search, manual creation,
confirmation Cancel via native Enter, Enter-to-confirm without duplicate deletion, and
selection toolbar placement just above a full-width table at desktop/390px widths.
Delayed-body checks hold
`Response.text()` after headers arrive, without dispatching synthetic Turbo events
or replacing controllers. Columns Apply holds its request before delivery because
that endpoint redirects to HTML rather than returning a Turbo stream.
Explicit waits exceed search debounce to assert no
premature request; other waits observe events or DOM state. The Journal runs its own pull
to refresh in mobile browsers, so the session is a plain touch browser rather than an
installed app. Narrow viewport checks include Chromium touch emulation, not real mobile
Safari coverage.
