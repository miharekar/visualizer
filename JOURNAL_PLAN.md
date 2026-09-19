# Journal implementation plan

Status: implementation updated after review and verified.

## Goal

Make Visualizer a coffee journal: manage imported brews, log manual brews,
record taste, recover successful recipes, and compare dialing-in attempts.

Acceptance scenarios:

1. Assign three coffees to seven shots, rate them, and edit notes without visiting
   seven edit pages. Enter moves down the same column for rapid rating.
2. Create and edit a manual brew without leaving the list.
3. Errors, delayed searches, retries, and changes in another tab must not silently
   discard edits or overwrite newer values.

## Confirmed interface

- Optional view of **`/shots`**, controlled by a default-off profile setting.
  Available to everyone; no beta gate or separate Journal page.
- Main navigation stays **Shots** and remains active on `/shots.html` redirects.
- Shared classic-index header: shot count, push-notification bell, **Columns**,
  **Upload**, and **Create**. Upload has no plus icon. Columns/Upload buttons
  show a depressed state while their panels are open.
- Header, upload panel, and column panel retain normal narrow sizing. Search
  and table use available screen width with responsive gutters, including
  ultrawide screens. Space separates table container from footer.
- No Journal heading or instructional subtitle. Serif font only on page heading.
- Compact content-sized rows and inputs. Table fills container if content is
  narrow and scrolls horizontally if wider. Numeric presentation follows normal
  shot cards: time rounded to one decimal; weights/TDS/EY up to four decimals.
  Formatting alone does not rewrite stored values.
- Always newest first. No row-sort/order controls.
- Infinite loading **inside** bounded table container, with sticky headers and
  native scrollbars. Height uses measured header/footer space with a **512px
  minimum**. Standard footer remains reachable.
- Table links disable Turbo hover prefetch, including newly loaded rows.
- Single search box for coffee, profile, notes, tags where entitled, and other
  supported text fields. **Brew timestamps are not searched.** Premium search
  is instant with no button; free users submit Search.
- Selection toolbar floats near viewport top without moving layout. Hidden
  until a row is selected; Compare appears only for exactly two selected rows.
  Maximum 100 selected shots per atomic edit. Action controls use pointer cursors.
- No "Saved" text. Errors appear directly below affected rows; associated cells
  get red backgrounds, without a red border. No global Retry button. Correcting
  or re-submitting an errored field creates a fresh save.

## Default columns — exact order

1. Enjoyment
2. Made at
3. Coffee — with coffee management; otherwise **Roaster**, then **Coffee bag**
4. Profile
5. Dose
6. Grind
7. Grinder
8. Yield
9. Time
10. Actions

- Enjoyment uses existing colors in a compact, centered editable badge.
- Made at is plain text, not a link.
- Actions contains View, Edit, Delete icons. Uses Heroicons eye and shared
  pencil/trash artwork from shot detail. Delete uses existing confirmation popup.
- Actions is a regular configurable column, at the end by default.
- With coffee management enabled, Roaster/Coffee bag name columns are absent
  from picker and defaults; bag-derived fields cannot be edited directly.
- With management disabled, managed Coffee column is absent. Manual roaster and
  coffee-name editing clears canonical selection rather than silently ignoring
  changed text.
- Optional fields include notes, tags, barista, roast details, TDS/EY, ratio,
  photo, tasting assessments, private notes, and configured custom metadata.
  Entitlements apply independently of column preferences.

## Column configuration and reusable editors

- Columns opens a borderless panel **above search**, with **Visible** and
  **Hidden** groups. Groups have no background and no checkboxes.
- Cross-group dragging changes visibility; within-group dragging changes order.
  Floating chip follows pointer, with faded placeholder and no orange outline.
  Chips have extra right padding; picker labels omit `(g)`/`(s)`.
- Arrow keys support reordering/transfers. Escape cancels dragging.
- Account-persisted order/visibility follows user across devices. **Reset stores
  SQL NULL** and restores defaults. Saves are quiet; errors remain local.
- Drop updates only moved column, skips unchanged DOM positions, and saves
  preferences after browser paint.
- Coffee bags, grinder, and unmanaged roaster/coffee-name editors reuse existing
  combobox partial/controller. Suggestions retain input focus during selection.
- Tags reuse existing Tagify controller: one tags input, no add/remove/replace
  action selector. A multi-shot edit applies the entered set to every selected
  shot; initial input shows shared tags.
- Dialog suggestions are positioned locally and can overflow the tag dialog;
  height is capped for short viewports. Single-shot buttons say **Save**;
  bulk buttons say **Apply to N shots**.
- Notes use existing rich-text editor, with explicit Save. Cancel/Escape saves
  nothing. No automatic delayed note saves.

## Undo and keyboard behavior

- Undo sits beside search, appears only after a successful edit, and steps
  backwards through successful shot edits in current page session.
- Each bulk edit is one undo operation. Search does not clear history.
- No per-cell Revert links or separate success bar.
- Ctrl/Cmd+Z invokes saved-edit undo when not editing text. No shortcut hint.
  Inputs and rich-text editors retain native text undo for active changes.
- Enter moves down same field and selects next value; Shift+Enter moves up.
- Undo checks affected saved values, preserves unrelated later edits, restores
  dependent coffee fields, and restores absence of newly added metadata keys.
- Creation/deletion and column preferences are separate from shot-edit undo.
  Deleting a shot removes undo entries that reference it.

## Manual creation and comparison

- Create opens inline panel with no "New shot" heading. Cancel/Add shot are
  right-aligned, with Add shot rightmost.
- Made at defaults to now in user's timezone; backdating allowed. No telemetry
  or profile required; measurements optional. Draft is not persisted until Add.
- Absence of `ShotInformation` identifies manual entries, with no origin column.
- Draft reuses ordinary shot UUID across retries. Server-generated SHA fingerprints
  creation payload: replaying changed values returns conflict and a link to saved
  shot, keeping revised draft instead of silently discarding it.
- Creation updates count/empty state. New row remains pinned until next search,
  marked when it does not match current filter.
- Existing rule retained: manual date/duration editable; imported values read-only.
  Information presence is only used for this rule, not comparison eligibility.
- Any two shots can be compared. Details/tasting assessments render even without
  telemetry; charts appear for whichever sides have data. Timing adjustment only
  appears when both sides have charts.
- Non-premium daily limit counts records **created in last 24 hours**, rather than
  brew dates, so backdating cannot bypass it.

## Rails / Hotwire implementation

- `Current.journal` is request-scoped and reset with Current. View selection uses
  explicit user preference and templates, not existence of an instance variable.
- `GET /shots` selects classic or Journal template. `POST /shots` creates manual
  shots via JSON or handles existing file uploads. JSON DELETE uses normal shot
  ownership policy and confirmation flow.
- `PATCH /shots/journal` handles bounded atomic updates and signed undo snapshots.
- `PATCH /profile/journal_columns` saves layout or NULL reset.
- `GET /shots/journal/cells` supplies requested cells for at most 100 owned,
  accessible shots. Called when revealing a column or opening its editor.
- `Journal.for_list` selects only base identifiers plus visible column attributes
  and their dependencies. Action Text, tags, and image associations load only
  when shown or explicitly edited. Telemetry JSON never loads for list rendering.
- `journals/row` is shared HTML row template, including action icons. Updates use
  Turbo Stream morphs rather than manually rebuilding/merging row HTML in JS.
  Partial column loads preserve existing cells; focused dirty/pending/error cells
  are protected through Turbo morph callbacks.
- Mutations await stream rendering before next queued save so row versions stay
  current. Partial reads do not advance optimistic write versions.
- Search and pagination responses carry search generation IDs. Stale searches
  cannot replace an active edit or overwrite a subsequently completed save.
- Pagination uses readable `before` timestamp and `before_id` UUID tie-breaker.
- Owner scope, premium fields, and free history cutoff apply on every read/write,
  including undo. History cutoff remains based on `created_at`, not brew time.
- Failed bulk operations are superseded per affected cell; old failed values are
  never replayed over individual corrections. Failed values remain available.
- Keep model validations/callbacks and integrations; no `update_all` edits.

## Verification checklist

- [x] Original seven-shot/three-coffee workflow, manual creation, desktop/mobile
      interaction, infinite loading and column persistence exercised in Chromium.
- [x] Regression tests for ownership, entitlements, metadata undo, stale edits,
      atomic rollback, creation replay, quotas, cursor ties, query preloading,
      dynamic column sets, profile redirects, and chartless comparison.
- [x] Native JS checks for save recovery, overlapping failures, search races,
      session undo, shortcut behavior and vertical Enter navigation.
- [x] Native JS tests added to `bin/ci` (Node 22.15+).
- [x] Current browser checks: Turbo row morphs, hidden Undo/push bell, compact
      rows, field-local errors, shared tags/grinder editors, short-viewport tag
      suggestions, delayed search during edits, lazy metadata loading, metadata
      undo, changed server-side columns, creation and confirmed deletion.
- [x] Complete final regression/style/security checks for this review pass.
- [x] Record final results below.

## Latest verification

- `bin/rails test`: **324 tests, 1,495 assertions**, no failures
  or errors.
- `node --test test/javascript/*_test.mjs`: **11 passing tests**.
- RuboCop: **260 files**, no offenses. Changed templates formatted with
  rustywind/htmlbeautifier; JavaScript formatted with Prettier.
- Brakeman: no security warnings. Bundler audit and Importmap audit: no known
  vulnerabilities (existing unversioned Highcharts pins are skipped by audit).
  Gitleaks: no leaks.
- Chromium verified error correction without blocking other rows, multi-step
  keyboard undo, vertical Enter, stale search protection, shared combobox and
  Tagify editors, short-viewport suggestion positioning, lazy custom columns,
  metadata undo, changing server-side columns, creation/counts, confirmed deletion,
  exact managed-mode defaults, and comparison of manual shots without charts.
- Browser-test account and its records were removed after verification.

Temporary browser tooling and fixtures live outside repository; no new runtime
Postgres connections with default parallel worker count.

## Research references

- [Visualizer #77: bulk editing](https://github.com/miharekar/visualizer/issues/77)
- [Visualizer #71: data-entry friction](https://github.com/miharekar/visualizer/issues/71)
- [Visualizer #242: preserve measured yield](https://github.com/miharekar/visualizer/issues/242)
- [Visualizer #162: preparation-method search](https://github.com/miharekar/visualizer/issues/162)
- [Beanconqueror](https://beanconqueror.com/) and [Filtru](https://filtru.coffee/)

Reddit request returned HTTP 403; no usable forum evidence was retrieved.
