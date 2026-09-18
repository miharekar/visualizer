# Journal implementation plan

Status: scope refined; implementation not started.

## Goal

Make Visualizer a useful coffee journal: manage imported brews, record taste,
recover successful recipes, and compare dialing-in attempts from one page.
First concrete acceptance scenario: seven shots using three coffees can be
assigned their coffees, rated, and annotated without visiting seven edit pages.
Second acceptance scenario: log a manual brew as a new row, with coffee,
brew time, dose, yield, duration, enjoyment, and notes, without leaving Journal.

Vladimir's September 2026 feedback supplies longer-term direction: recording
every shot becomes a chore once users know their preferences. Learning from
others brewing the same coffee could make history useful again, particularly
for the first shots from a new bag. Lower logging friction now; preserve
structured coffee identity for future community discovery.

## Confirmed decisions

- Name: **Journal**, separate `/journal` resource.
- Available to everyone. No beta gate.
- Add account setting to show Journal instead of existing shot index; default
  off. This supersedes initial beta-only rollout and deferred setting proposal.
- Existing shot index remains available.
- Create manual shots directly in Journal through an inline new-row workflow.
- Desktop-first; usable on mobile. No double-tap requirement for core editing.
- Immediate saving with session-scoped revert to immediately preceding saved
  value. A bulk operation is one undoable action. Undo does not survive reload
  or navigation; durable revision history is outside initial scope.
- Free users can sort and submit searches. Preserve submitted-search behavior
  rather than enabling premium-style instant filtering for free users.
- Free users cannot view or edit old shots through Journal. Preserve existing
  history cutoff and field entitlements.
- Essentials first; column visibility and order persist on user account and
  follow user across browsers/devices from initial release.
- Use existing Rails, Turbo, Stimulus, and Tailwind stack. No third-party grid
  or spreadsheet JavaScript dependency.

## Initial interface

Coffee-aware table using familiar spreadsheet interactions and existing
Visualizer styling. Display values normally; activate editors when needed.

- Inline editing and row selection.
- **Add shot** opens an inline draft row; no separate creation page.
- Selected-row toolbar: assign coffee, set field, add/remove tags where allowed.
- Search/filter/sort across accessible history, not only loaded rows.
- Sticky selection/date context during horizontal scrolling.
- Notes previews and rich-text editing in expandable details/side panel.
- Links to existing chart and comparison workflows.
- Column show/hide and reorder, persisted to user account.
- Single-tap editing on mobile with visible controls.

Rectangular selection, multi-cell paste, and fill-down remain exploratory:
implement only if needed to make initial workflows effective. Start with a
semantic HTML table and small Stimulus interactions, not a general spreadsheet
engine.

### Proposed default columns

| Column | Behavior |
| --- | --- |
| Brewed | Brew date/time; editable for manual shots, imported shots read-only initially |
| Coffee | Roaster and coffee; searchable assignment editor |
| Profile | Existing profile title; editable |
| Dose | Editable |
| Yield | Editable |
| Time | Duration; editable for manual shots, imported shots read-only initially |
| Grind | Editable setting |
| Enjoyment | Existing 0–100 score and color treatment |
| Notes | Shot-note preview; rich-text editor |

Additional columns: grinder, tags, barista, roast date/level, TDS/EY, tasting
assessments, and custom metadata, subject to existing entitlements. Bean notes
and private notes available in details. Final default layout needs validation
against realistic data and viewport widths.

Coffee assignment follows existing modes: own bags when coffee management is
enabled; canonical coffee search and manual roaster/coffee fields otherwise.
Never overwrite dose/yield or other measurements when assigning coffee.

## Manual shot creation

Proposed interaction:

- **Add shot** opens a draft row, even when history is empty. Focus coffee picker;
  default brewed time to now in user's time zone. Allow backdating.
- Enter available details without requiring a profile, telemetry, or an upload.
  Measurements and notes are optional; never fabricate defaults for them.
- Explicit **Add shot** commits draft; Cancel removes it without creating a
  record. Existing-row edits continue to autosave. This avoids persisting an
  empty shot merely because user entered or tabbed through a new row.
- Once created, row uses normal autosave/revert. Keep it visible long enough to
  finish editing even if current filters or sort would place it elsewhere;
  indicate when it does not match current filters.
- Failed creation retains draft and field errors. Repeated submissions/retries
  must not create duplicate shots.
- Manual brew date/time and duration remain editable after creation. Represent
  manual origin explicitly, rather than inferring it from missing chart data.
- Respect existing free daily creation limit and premium field entitlements.
- Chart/profile actions are unavailable when no corresponding data exists;
  manual rows still support ordinary journal and coffee-management workflows.

Creation is separate from field revert: cancel works before creation; after
creation, use existing single-shot deletion behavior if row needs removing.
Do not imply that session undo automatically deletes a newly created shot.

## Saving and undo

- Ordinary cells commit on Enter, Tab, or blur; Escape cancels uncommitted edit.
- Notes save after typing pause; preserve rich-text formatting.
- Show Saving / Saved / Couldn't save without disruptive notifications.
- Send only changed fields; distinguish omitted values from explicit clearing.
- Failed saves retain entered values and offer retry.
- Per-cell Revert shows and restores preceding saved value through server save.
- Bulk Undo restores complete operation, including coffee fields changed by
  model callbacks. Restore original values separately for each affected shot.
- Check concurrency for edits and undo; never overwrite newer changes silently.
- Serialize/coalesce overlapping saves so older responses cannot replace newer
  input. Do not refresh editable rows in ways that discard active edits.
- Bulk operations commit atomically or return actionable field/row errors.

## Existing code and constraints

- `app/controllers/shots_controller.rb`: current listing, search, editing,
  coffee-bag loading, history handling.
- `app/controllers/shots/editing.rb`: shared permitted fields and premium rules.
- `app/models/shot.rb`: coffee assignment callbacks, tags, metadata, history scopes.
- `app/javascript/controllers/shot_copier_controller.js`: highlight/revert UX
  reference. Existing revert modifies an unsaved form; Journal undo must persist.
- `app/views/shots/_form.html.erb`: field editors and entitlement-specific UI.

Important implementation constraints:

- Current free history uses `created_at` within one month, not brew `start_time`.
  Existing direct owner edit does not enforce that cutoff. Journal must enforce
  it for both reads and writes, including direct requests and undo.
- Authenticate and owner-scope all requested shots and own coffee bags.
- Preserve premium rules for coffee management, tags, custom metadata, private
  notes, and tasting assessments. Review read serialization as well as writes.
- Numeric-looking values such as grinder setting and weights are often strings.
  Preserve legitimate existing values rather than coercing indiscriminately.
- Coffee assignment changes related fields. Return authoritative updated rows.
- Rich notes must not be flattened by unrelated cell saves.
- Merge individual metadata edits without dropping untouched keys.
- Tag setters mutate associations during assignment; transactions must cover
  assignment as well as save.
- Use model saves, not `update_all`, to preserve validation and integrations.
- Stable pagination/sorting must handle equal timestamps.
- Existing shot-card live broadcasts cannot replace Journal rows directly.
- Manual creation must satisfy `Shot` identity requirements (`sha`, owner,
  `start_time`) server-side without pretending to be an uploaded file. Inspect
  identity/deduplication callers before choosing representation.
- Audit source detection, chart rendering, exports, notifications, and Airtable
  sync for shots without `ShotInformation`. Keep ordinary model callbacks.
- Validate manual timestamps and duration server-side, including time zones and
  blank/invalid values. Creation-only fields must not silently become editable
  on imported shots through a generic batch payload.
- Keep web Journal separate from public API. Check OpenAPI impact if shared
  behavior changes; bump `info.version` whenever `openapi.yaml` changes.

## Implementation checklist

### 1. Validate native table and interaction design

- [ ] Build server-rendered semantic table using existing Rails/Turbo patterns;
      use Stimulus for inline editors, selection, keyboard handling, and undo.
- [ ] Validate coffee and rich-text editors, dark mode, accessible column
      controls, and mobile interaction with existing components.
- [ ] Confirm default columns using seven-shot/three-coffee scenario.
- [ ] Validate inline manual creation, including empty history and active filters.

Third-party grids were explored during discovery; implementation uses native
HTML and existing Hotwire stack. Keep behavior specific to Journal workflows.

### 2. Account preference and navigation

- [ ] Add persisted preference, default false, and profile settings control.
- [ ] Persist column visibility/order on user account using stable identifiers;
      validate allowed columns, preserve sensible defaults for newly added
      columns, and apply premium entitlements independently of preferences.
- [ ] Trace default landing page, navigation, and redirects; honor preference
      consistently without redirect loops or changing chart/detail URLs.
- [ ] Keep explicit access to both Journal and existing shot index.
- [ ] Test default-off behavior and setting persistence for free/premium users.

### 3. Journal resource and data access

- [ ] Add `GET /journal` for page and bounded/paginated row data.
- [ ] Add `PATCH /journal` for bounded batches of changed fields.
- [ ] Add a RESTful manual-shot creation endpoint, separate from file-upload
      handling; choose resource path consistently with repository conventions.
- [ ] Implement explicit manual origin and server-generated identity after
      tracing existing parser/source/deduplication behavior.
- [ ] Support manual brew timestamp/duration on create and subsequent edits.
- [ ] Preserve creation limits and prevent duplicate creation on retries.
- [ ] Share existing editable-field rules without copying controller logic.
- [ ] Enforce ownership, history cutoff, and premium entitlements server-side.
- [ ] Implement submitted search/sorting for free users and preserve premium
      instant-filter behavior; inspect current search paths before sharing them.
- [ ] Validate payload shape, fields, IDs, and batch limits before mutation.
- [ ] Add atomic bulk updates and concurrency checks under appropriate locks.
- [ ] Return updated rows and useful validation/conflict errors.

### 4. Journal editing interface

- [ ] Render table, keyboard-accessible editors, selection, and bulk toolbar.
- [ ] Add inline draft row, create/cancel controls, and transition to saved row.
- [ ] Implement coffee assignment with existing coffee-management modes.
- [ ] Add enjoyment, measurement, and rich-note editing.
- [ ] Add save states, retry, per-cell revert, and bulk undo.
- [ ] Add details panel and chart/comparison entry points.
- [ ] Add column visibility/order controls backed by account preferences.
- [ ] Preserve active edits during search, pagination, navigation, and failures.

### 5. Verification and completion

- [ ] Verify seven shots / three coffees can be managed without leaving Journal.
- [ ] Verify manual creation and subsequent edits without telemetry, including
      time zones, backdating, optional measurements, validation failures,
      cancellation, duplicate retries, and free-user creation limits.
- [ ] Verify manual shots work in existing index/details, coffee management,
      exports, notifications, and integrations; omit unsupported chart actions.
- [ ] Test unauthenticated requests, foreign shot/bag IDs, old free-history
      records, premium fields, malformed requests, and direct endpoint access.
- [ ] Test multi-row success, rollback, clears, stale edits, and undo side effects.
- [ ] Verify rich notes and untouched metadata survive unrelated edits.
- [ ] Verify pagination ties and history-wide search/sorting.
- [ ] Verify column preferences persist across sessions/devices and remain
      valid when available columns or premium entitlements change.
- [ ] Exercise rapid edits, failed saves, keyboard-only use, and mobile tapping.
- [ ] Run relevant Rails tests and RuboCop; format changed templates with
      rustywind/htmlbeautifier and JavaScript with Prettier.
- [ ] If dependencies change, run required security/dependency checks.
- [ ] Update this checklist and record final interaction decisions.

## Concrete follow-ups

- **Community discovery by coffee:** explore other users' successful brews with
  same coffee, particularly for dialing in a new bag. Separate product discovery;
  does not depend on recruiting roasters to publish recipes.

Other features require a concrete user workflow before entering this plan.
Manual creation is part of initial delivery.

## Research references

- [Visualizer #77: bulk field editing](https://github.com/miharekar/visualizer/issues/77)
  — assign common coffee details across many shots; previously deferred to Airtable.
- [Visualizer #71: streamline data entry](https://github.com/miharekar/visualizer/issues/71)
  — fewer repeated interactions matter more than keyboard support alone.
- [Visualizer #242: copied yield overwrites measurement](https://github.com/miharekar/visualizer/issues/242)
  — preserve imported measurements unless explicitly edited.
- [Visualizer #162: preparation-method search](https://github.com/miharekar/visualizer/issues/162)
  — interest extends beyond machine-specific espresso profiles.
- [Beanconqueror](https://beanconqueror.com/) and [Filtru](https://filtru.coffee/)
  — examples of bean-centered history, taste notes, and repeatable brewing.
- [Tabulator range interactions](https://tabulator.info/docs/6.3/range)
  and [license](https://tabulator.info/docs/6.3/license).
- [AG Grid Community vs Enterprise](https://www.ag-grid.com/javascript-data-grid/community-vs-enterprise/).

Reddit access was blocked and forum searches yielded no usable evidence;
community-demand conclusions above rely on linked Visualizer issues, not
unverified forum claims.
