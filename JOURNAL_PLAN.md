# Journal v1

## Goal

Make shot history useful as a coffee journal: assign coffees, rate brews, record
taste, recover recipes, and compare dialing-in attempts without visiting a full
edit page for every shot.

Journal remains an optional, default-off view of `/shots`, available to everyone.
Existing premium fields, coffee management, and free-history restrictions apply.

## Interaction

- Compact, newest-first table with sticky headers and native scrolling.
- Default columns: Enjoyment, Made at, Coffee, Profile, Dose, Grind, Grinder,
  Yield, Time, Actions. Without coffee management, Roaster and Coffee bag replace
  Coffee.
- Simple cells are Rails forms. Changes save on change/blur; Enter submits and
  moves down the column, Shift+Enter moves up. Pending inputs are readonly.
- Coffee, grinder, tags, and notes open a server-rendered popup with Save/Cancel.
  Native dialogs handle modal focus and Escape; existing combobox, Tagify, and
  rich-text widgets are reused. Cancel/Escape discards the editor without saving.
  Footer places Cancel immediately left of Save. Coffee/grinder suggestions can
  extend outside the dialog; long notes and tag forms scroll within it.
- Select up to 100 shots for an atomic bulk field edit. Tags replace the selected
  shots' tag sets; editor starts with their shared tags. Exactly two selections
  expose Compare. Selection toolbar floats above the page without moving the table.
- Search targets the results frame and updates browser history. Premium users
  get debounced search; free users submit Search. Editor frame sits outside results;
  modal dialogs prevent background interaction while editing.
- Infinite pagination stays inside the scroll container. Pagination targets are
  scoped to each results instance so old pages cannot append into a newer search.
- Columns have Visible and Hidden groups, with no checkboxes. Drag within or
  between groups using grips and a floating preview, then Apply. No keyboard
  reordering or instructional text. Cancel discards staged changes. Reset to
  defaults sits separately on the left and stages defaults until Apply stores
  SQL NULL. A separate controller handles picker movement only. Apply reloads
  results, clearing selection and loaded pages.
- Create, full Edit, and View use Turbo Drive. `/shots/new` renders the existing
  shot form, not an inline draft. Manual brew time and duration are editable;
  imported values stay read-only. Failed validation keeps form values.
- Coffee labels use `Coffee name - Roaster (roast date)`, omitting absent parts.
- Delete uses existing confirmation UI and explicit removal/count streams.
- No journal-specific ARIA state machinery. Native labels and named controls
  provide basic accessibility.

## Rails and Hotwire

- `GET /shots`: classic index or journal according to user preference.
- Results frame wraps table, selection toolbar, empty state, and pagination.
- Cell frames sit inside `<td>` elements. No frames or forms wrap table rows.
- `GET /shots/journal/edit`: renders one field editor for owned selected shots
  inside a native dialog. Successful saves clear the editor frame to close it.
- `PATCH /shots/journal`: accepts selected IDs and one field/value, or coffee
  attributes. Returns actual Turbo Streams, never JSON-wrapped stream HTML.
- Successful saves update affected cells and dependent read-only values, not
  whole rows. Other cell edits remain untouched. Bulk success clears selection.
- Validation errors return 422 streams with attempted values and local errors.
  Failed cell requests keep values and offer Enter to retry; no automatic replay.
- `PATCH /profile/journal_columns`: saves layout then redirects to HTML results.
- List queries load ordinary shot attributes and preload visible expensive
  associations. Telemetry JSON is not loaded for journal rendering.
- Cursor uses brew timestamp plus UUID for stable pagination across tied times.
- Updates retain model callbacks and transactional tag assignment. No `update_all`.
- Only submitted fields change. Concurrent writes to the same field use ordinary
  last-write-wins behavior; no custom cross-tab version protocol.

## Removed from v1

- Saved-edit undo, signed snapshots, and global undo shortcuts. Native text undo
  still works. Saved-edit undo is follow-up work in a separate PR.
- Row morphing, dirty-cell protection callbacks, shadow row state, mutation queue,
  render-completion markers, and failed-operation reconstruction.
- Client-generated draft IDs, creation fingerprints, replay conflict recovery,
  and newly created rows pinned outside current search.
- Hidden-cell hydration and live table surgery when changing columns.
- Search pause/replay machinery and exact header/footer viewport measurement.

Keep ownership, coffee ownership, premium allowlists, ordinary validation, rich
text sanitation, atomic bounded bulk saves, and creation-time-based daily limits.
Unexpected errors may fail normally rather than growing a client recovery engine.

## Verification

Regression coverage targets observable behavior rather than removed protocols:

- Cell-only stream updates, local validation errors, Enter navigation/retry.
- Bulk atomicity, shared tags, metadata merging, and canonical coffee clearing.
- Ownership, premium/history restrictions, imported/manual field restrictions.
- Frame search, scoped pagination, tied timestamps, and column Apply/Reset.
- Shared form creation, failed validation, uploads, and API regression checks.
- Existing chartless comparison and expensive-association preload checks.

Chromium checks cover rapid overlapping cell saves, network retry, 422 errors,
bulk tags, notes across searches, coffee assignment, columns, and manual creation.
Mobile checks use a 390px touch-emulated viewport; real iOS Safari is not covered.
Temporary browser scripts and fixtures live outside the repository.
