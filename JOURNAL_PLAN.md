# Journal implementation plan

Status: implemented and verified.

## Goal

Make Visualizer a useful coffee journal: manage imported brews, log manual
brews, record taste, recover successful recipes, and review dialing-in attempts.

Acceptance scenarios:

1. Seven shots using three coffees can be assigned coffees, rated, and annotated
   without visiting seven edit pages.
2. A manual brew can be created and subsequently edited without leaving list.

Vladimir's September 2026 feedback supplies longer-term direction: logging
becomes a chore once users know their preferences. Learning from others brewing
the same coffee could make history useful again, especially with a new bag.
Reduce logging friction now; preserve structured coffee identity for future
community discovery.

## Confirmed decisions

- Journal is an optional **view of `/shots`**, not a separate destination.
- Account setting defaults off and is available to everyone. No beta gate.
- Main navigation still says **Shots** and stays active in either view.
- Reuse classic shot-index header width, count heading, push notification
  button, Upload button/panel, and drag-and-drop upload behavior. Add **Create
  a shot** beside those controls. Header, Upload, and Columns panels remain
  narrow; search/table container uses full screen width with responsive gutters,
  including ultrawide screens.
- All columns size from content without compact/non-compact categories. Inputs
  grow while typing, capped for long text. Table fills its container when content
  is narrow and scrolls horizontally when content is wider.
- No Journal heading or instructional subtitle.
- Rails/Turbo/Stimulus/Tailwind only; no grid/spreadsheet dependency.
- Desktop-first, usable on mobile with single-tap controls.
- Ordinary cells are inputs all along, styled as text until focused. No
  duplicated text display and hidden input.
- **Enjoyment first by default**, with existing red-to-green color treatment in
  a compact 36px editable badge centered in its cell.
- Brewed time links to existing shot page. No Details column or details panel.
- Always newest-to-oldest; no Sort/Order controls or alternate row ordering.
- Infinite loading, using existing lazy Turbo-frame pattern. Cursor uses brew
  timestamp and shot UUID so equal timestamps do not skip rows.
- Table sits in a bounded, viewport-relative scroll container with native
  horizontal/vertical scrollbars and sticky headers. Infinite-loading sentinel
  is inside this container; standard page footer remains reachable below it.
  Height uses measured space above table and footer height, not a fixed pixel
  allowance; resize observation keeps it correct as panels open or close.
  Table links disable Turbo hover prefetch, including newly loaded rows.
- Premium search is instant and preserves focus; no Search button. Free users
  submit search explicitly. Search field fills remaining header-row width.
- Single search box covers coffee, notes, profiles, tags (premium), and brew
  dates in user's timezone. Combined terms match across fields; no separate
  date/coffee/tag search controls.
- Free users cannot read/edit old shots through Journal. Existing cutoff is
  based on upload `created_at`, not brew time. Premium field entitlements apply.
- Column visibility and order persist on account from initial rollout.
  `journal_columns = NULL` means default layout; empty settings also fall back.
- Columns button sits immediately left of Upload; configuration panel is hidden
  until opened, above search, with no outer border. Drag handles replace arrow
  buttons; pointer dragging and arrow-key reordering save account preferences.
  Escape cancels dragging. Reset persists SQL NULL and restores default order
  and visibility immediately.
- Column updates and Reset save quietly; failures still show retry feedback.
- Existing-row edits save immediately on commit, with session-scoped per-cell
  revert and bulk undo. Undo restores preceding saved value, not original value
  from page load, and preserves unrelated later edits.
- Notes use rich-text dialog with explicit **Save notes**. Cancel/Escape saves
  nothing. This supersedes initial delayed-autosave proposal for notes.

## Columns and workflows

Default columns, in order:

1. Enjoyment
2. Brewed
3. Coffee
4. Profile
5. Dose
6. Yield
7. Time
8. Grind
9. Notes

Additional columns: grinder, roaster, coffee name, barista, roast date/level,
TDS/EY, bean notes, tags, private notes, tasting assessments, custom metadata.
Premium entitlements govern availability independently of saved column choices.

Coffee assignment uses own bags when coffee management is enabled; otherwise
canonical coffee search and manual roaster/name fields. Assignment preserves
measurements. Bulk toolbar supports coffee assignment, setting individual
fields, adding/removing tags, and entering existing two-shot comparison.
Selection toolbar is hidden with no selection and floats 5rem below viewport top
when rows are selected, without moving table layout. Save/error status remains
separate from selection controls.

Manual shots:

- **Create a shot** opens inline creation panel without “New shot” heading.
- Brew time defaults to now in user's configured time zone; backdating allowed.
- Coffee, profile, measurements, enjoyment, and rich notes can be entered.
- Cancel and Add shot are right-aligned; Add shot is rightmost.
- No record until Add shot succeeds. Cancel abandons draft.
- Absence of `ShotInformation` identifies manual entry; no manual-origin column.
- Draft keeps one ordinary shot UUID across retries, preventing duplicate
  creation. Required `sha` generated server-side.
- No telemetry/profile required; measurements optional. Manual duration can be
  edited in row; manual brew time through Set field. Imported timestamp and
  duration stay read-only.
- Existing free daily creation limit and premium field entitlements apply.
- Creation is separate from field undo; use existing shot deletion if needed.

## Persistence and safety

- `GET /shots` renders classic index or Journal based on account preference.
- `POST /shots` creates manual shot via JSON or handles existing file uploads.
- `PATCH /shots/journal` saves bounded batches
  or reverts signed snapshots. These are internal session-authenticated writes.
- `PATCH /profile/journal_columns` persists account layout.
- Profile saves explicitly redirect to HTML so Turbo navigates and shows flash
  notice instead of treating destination as a list-update stream. Shots navigation
  uses controller/action matching, remaining active on `/shots.html` too.
- Share editable-field rules through `Shot.editable_attributes(user)`.
- Owner-scope shots and own coffee bags. Recheck history and premium access on
  every write, including undo.
- Maximum 100 distinct shots per atomic batch. Use model saves to preserve
  validation, tag/note setters, coffee callbacks, broadcasts, and Airtable sync.
- Preserve string-valued measurements/grinder settings, omitted fields,
  untouched metadata, and rich-text formatting.
- Serialize client saves; retain failed edits independently and continue saving
  other cells. Correcting a failed value replaces its failed operation. Offer
  retry/reload without making validation errors block the entire editor.
- Lock records and check versions for edits. Signed undo snapshots check
  affected values, preserving unrelated later edits and rejecting conflicts.
- Coffee undo includes related fields changed by assignment callbacks.
- New rows remain visible until next search; background uploads do not replace
  actively edited rows. Infinite loading skips already-present row IDs.
- Existing chartless shot views tolerate missing duration; profile download
  returns documented 422 for manual shots. OpenAPI version bumped accordingly.

## Implementation checklist

- [x] Inspect routes, preferences, editing rules, parsers, callbacks, and tests.
- [x] Add default-off Journal setting and nullable account column preferences.
- [x] Select interface at `/shots`; preserve Shots navigation and settings flow.
- [x] Share classic index header, sizing, notification and upload controls.
- [x] Implement native table, text-styled inputs, enjoyment colors, coffee picker.
- [x] Add atomic bulk editing, tag operations, version checks, signed undo.
- [x] Add rich-note editing with explicit save and Escape cancellation.
- [x] Add manual creation, retry identity, timestamp/duration support.
- [x] Add account column visibility/order controls and NULL reset fallback.
- [x] Add newest-first infinite loading with timestamp/UUID cursor.
- [x] Add submitted free search and focus-preserving premium instant search.
- [x] Keep existing chart/comparison entry points; handle chartless manual shots.
- [x] Finish controller/model regression checks and browser smoke checks against
      latest UI changes, including settings enablement, NULL preferences,
      cancellation, pagination, failed saves, keyboard and mobile use.
- [x] Format templates with rustywind/htmlbeautifier and JavaScript with Prettier.
- [x] Run RuboCop and relevant security checks; record final results below.

## Verification log

- `PARALLEL_WORKERS=1 bin/rails test`: 308 tests, 1,358 assertions, no failures,
  errors, or skips.
- `node --test test/javascript/journal_controller_test.mjs`: two passing native
  Node tests for validation recovery, independent saves, and retry behavior.
- Brakeman: no security warnings or scan errors.
- RuboCop: 260 files, no offenses. Gitleaks: no leaks.
- Latest focused rerun after UI refinements: 24 Rails tests, 155 assertions,
  plus both JavaScript queue tests passing.
- Chromium smoke checks have exercised inline save/revert, bulk assignment,
  note save/Escape cancellation, manual creation, column persistence, infinite
  loading, premium search retaining focus, and mobile coffee editing.
- Chromium reproduced invalid Enjoyment `101`, verified another field still
  saves, then corrected score to `90` without reloading. Verified badge's width
  and horizontal centering through actual computed geometry.
- Default parallel Rails test execution exhausted local Postgres connections;
  use `PARALLEL_WORKERS=1` for remaining checks.
- Temporary browser tooling installed outside repository; no app dependency.

## Concrete follow-up

Community discovery by coffee: find other users' successful brews with same
coffee, particularly for dialing in a new bag. Separate product discovery;
does not depend on recruiting roasters to publish recipes.

## Research references

- [Visualizer #77: bulk editing](https://github.com/miharekar/visualizer/issues/77)
- [Visualizer #71: data-entry friction](https://github.com/miharekar/visualizer/issues/71)
- [Visualizer #242: preserve measured yield](https://github.com/miharekar/visualizer/issues/242)
- [Visualizer #162: preparation-method search](https://github.com/miharekar/visualizer/issues/162)
- [Beanconqueror](https://beanconqueror.com/) and [Filtru](https://filtru.coffee/)

Reddit request returned HTTP 403; forum searches yielded no usable evidence.
Demand conclusions rely on linked Visualizer issues and supplied user feedback.
