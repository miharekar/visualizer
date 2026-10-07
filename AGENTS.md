# Visualizer

This file provides guidance to AI coding agents working with this repository.

## What is Visualizer?

Visualizer is a coffee telemetry and sharing app. It ingests brew history files and API uploads from Decent, Beanconqueror, Gaggiuino, GaggiMate, Smart Espresso Profiler (CSV), and other sources, then charts flow/pressure/temperature curves. Users manage roasters and coffee bags, add tasting notes, share shots publicly or with the community, and unlock metadata/tagging/older history with premium. An OAuth + basic-auth API allows third-party clients to upload and fetch shot data.

# Token efficiency

Respond like smart caveman. Cut all filler, keep technical substance.
- Drop articles (a, an, the), filler (just, really, basically, actually).
- Drop pleasantries (sure, certainly, happy to).
- No hedging. Fragments fine. Short synonyms.
- Technical terms stay exact. Code blocks unchanged.
- Pattern: [thing] [action] [reason]. [next step].

## Development Commands

### Setup and server

```bash
bin/setup              # install gems, prepare DB, clear logs/tmp, start bin/dev unless --skip-server
bin/dev                # Overmind: Rails server on PORT (3000 default), tailwind watcher, SolidQueue worker, Hot Cell
PORT=4000 bin/dev      # override port
bin/jobs               # run SolidQueue supervisor/worker if you want it outside bin/dev
```

Development URL: http://localhost:3000  
Create a user at `/registrations/new` (Turnstile verification only runs in production).

### Testing

```bash
PARALLEL_WORKERS=10 bin/rails test      # full Minitest suite (10 workers)
node --test test/javascript/*_test.mjs   # native JavaScript tests (Node 22.15+)
bin/rails test test/models/shot_test.rb # single file
bin/rails test test/models/shot_test.rb:123 # single test by line number
bin/rails test test/models/shot_test.rb -n /test_name/ # single test by name
bin/ci                                  # CI pipeline (style, security, tests, seeds)
env RAILS_ENV=test bin/rails db:seed:replant # must pass in CI
```

`bin/ci` runs: bin/setup --skip-server, RuboCop, bundler-audit, importmap audit, Brakeman, Gitleaks audit, Rails tests, JavaScript tests, and `db:seed:replant`.
Use `PARALLEL_WORKERS=10` for Rails test runs and `bin/ci`; default CPU-count parallelism can exhaust local Postgres connections.
Parser fixtures for upload/tests live in `test/files/`.

### Database

```bash
bin/rails db:prepare   # create DBs and run migrations
bin/rails db:migrate   # apply new migrations
bin/rails db:reset     # drop/create/migrate primary DB
bin/rails db:seed      # load seed data
```

Primary data lives in Postgres (`primary`).

### Other utilities

```bash
bin/rubocop            # rubocop-rails-omakase baseline
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
bin/bundler-audit
bin/importmap audit
bin/gitleaks-audit
bin/rails tailwindcss:watch # usually handled by bin/dev
```

### Hot Cell

Image variants run in the `hotcell` Kamal accessory, built from `hotcell/` and pushed as `ghcr.io/miharekar/visualizer-hotcell:latest`. App deploys never touch it. In development `bin/dev` runs it as the `cell` process; restart that after changing `hotcell/`.

Rebuild and reboot it after changing `hotcell/` or `.ruby-version`, after bumping Hot Cell gems, and periodically for libvips and Debian security patches:

```bash
docker buildx build --pull --no-cache --platform linux/amd64,linux/arm64 --build-arg RUBY_VERSION=$(cat .ruby-version) -t ghcr.io/miharekar/visualizer-hotcell:latest --push hotcell
bundle exec kamal accessory reboot hotcell   # pulls :latest and replaces the container; image calls fail for a few seconds
bundle exec kamal accessory details hotcell  # expect "(healthy)" on hvapp and hvapp2
```

- `--pull --no-cache` takes the newest Ruby base image and reruns `apt-get upgrade`; a cached build ships the old libvips.
- Changing only the accessory's settings in `config/deploy.yml` needs just the reboot.
- libvips decodes images in memory (`VIPS_DISC_THRESHOLD` in `hotcell/config.rb`); its default temp file for images over 100 MB decoded can't fit under the cell's `file_size`. A worker fits about 460 MB decoded (11000×11000 RGBA); bigger images fail permanently and `ProcessImageJob` purges them.
- Bumping Hot Cell: set one version for `hotcell-client` in `Gemfile` and for `hotcell-server` and `activestorage-hotcell-server` in `hotcell/Gemfile`, then run `bundle install` and `BUNDLE_GEMFILE=hotcell/Gemfile bundle install`. Dependabot only watches the root `Gemfile`, so never ship its `hotcell-client` bump without the cell side. Build the cell image, push to `main`, then reboot the cell as soon as the CI deploy finishes; until both sides match, a protocol change fails calls with transient `protocol` errors.
- Updating the cell's other gems (ruby-vips, image_processing, ffi): `BUNDLE_GEMFILE=hotcell/Gemfile bundle update --all`, then rebuild and reboot.
- On Rails 8.2: replace `hotcell-client` with `activestorage-hotcell-client` (same version), delete `HotCellImageTransformer` from `config/initializers/hotcell.rb` and the `hotcell.variant_transformer` initializer from `config/application.rb`, and set `config.active_storage.variant_processor = ActiveStorage::HotCell::Client::Transformers::Image::Vips` instead of `:disabled`.

### Build and lint quick picks

```bash
bin/rubocop            # Ruby lint/style
bin/rails test         # app tests
bin/ci                 # full CI pipeline
```

## Architecture Overview

### Data and storage

- ActiveRecord primary DB is Postgres.
- ActiveStorage uses local disk in development/test; S3 buckets configured in `config/storage.yml` for production.
- Image variants are processed in a Hot Cell sidecar (`hotcell/`, Kamal accessory `hotcell`), never in the app; the app has no libvips. Updating, rebuilding, and rebooting it: see Hot Cell under Development Commands.
- Solid Cache backs Rails caching; AppSignal handles monitoring/tracing.
- All tables use UUID primary keys (see `db/schema.rb`).

### Concerns & modules

- Shared model behavior lives in `app/models/concerns`; use `ActiveSupport::Concern` when you need `included` blocks or `class_methods` (`Airtablable`, `Sluggable`, `Squishable`).
- Pure helper mixins can remain as plain modules in concerns (`Bsearch`, `DateParseable`, `ShotPresenter`).
- Class-scoped modules live under the class name in `app/models/<class>/` and are included in the class (e.g., `Shot::Jsonable`, `ShotInformation::Profile`, `ShotChart::Process`).
- Controller mixins live in `app/controllers/concerns` (`Authentication`, `Authorization`, `Filterable`, `Paginatable`); prefer these over fat controllers.
- Integration/service wrappers live in `app/lib` (autoloaded); keep `lib/misc` for experiments only.

### Domain model

- `User` has password + optional WebAuthn passkeys, premium flags, time zone/skin preferences, and many `Session` records.
- `Shot` is the core brew record with profile metadata, attachments, tags, and optional `ShotInformation` JSON for charting.
- `ShotInformation` stores parsed brew data, profile fields, and parser metadata (`parser_name` detects Decent/Beanconqueror/Gaggiuino/GaggiMate/SEP CSV).
- `CoffeeBag` belongs to a `Roaster`; canonical roaster/bag records back autocomplete and community sharing.
- Coffee bag freezer lifecycle uses `frozen_date` and `defrosted_date` naming consistently across model/controller/views/API.
- `SharedShot` issues short codes for public shares and Beanconqueror deep links; `ShotTag`/`Tag` provide tagging.
- `Update`, `Stats`, `YearlyBrew`, and `Community` controllers back the public change log and discovery pages.

### Ingestion & API

- Shot uploads go through `Shot.from_file` (dispatches parsers under `app/models/parsers`) from the web UI or `/api/shots/upload`.
- API controllers (`/api/shots`, `/api/roasters`, `/api/coffee_bags`, `/api/me`) accept Doorkeeper OAuth tokens (`read`/`upload`/`write` scopes) or HTTP basic auth; session cookies are not used. `Api::BaseController#json_request?` is always true, so premium/authorization failures render JSON regardless of the request format.
- Coffee bag API is root-level (`/api/coffee_bags`) and supports optional `roaster_id` query filtering.
- Shots can be downloaded as JSON/CSV/TCL profiles via `/api/shots/:id/profile` and shared via `/api/shots/shared?code=...`.
- OAuth apps are managed at `/oauth/applications` after login.
- Keep `openapi.yaml` tightly aligned with `config/routes.rb` and controller behavior (auth requirements, scopes, response shapes, redirects, and deprecated aliases).
- When `openapi.yaml` changes, bump `info.version` once relative to `main` for the branch/PR. Reuse that version for subsequent edits on the same branch; do not bump per commit.
- Any API behavior change also requires checking whether `openapi.yaml` must be updated, even if the route itself did not change (for example response fields, visibility rules, auth behavior, or parameter semantics).

### Authentication & authorization

- Sessions are cookie-based (`Session` records); login via password, registration, and passkeys (WebAuthn).
- Doorkeeper manages OAuth applications/tokens; `AuthConstraint.admin?` gates Mission Control Jobs and PgHero.
- Action Policy governs shot ownership for updates/destroys; non-premium users have a best-effort 30 shots/day creation cap and only see recent history.

### Background jobs

- ActiveJob uses Solid Queue. Run with `bin/jobs`; recurring tasks live in `config/recurring.yml` (shared shot cleanup, dropdown/autocomplete population, Airtable webhook refresh, Loffee Labs importer, premium feedback, duplicate Lemon Squeezy subscriptions, tag cleanup).
- Mission Control Jobs is mounted at `/jobs` for admins; PgHero at `/pghero`.
- Jobs handle Airtable sync, image processing, dropdown population, premium notifications, and web push delivery.

### Frontend stack

- Rails 8 with Propshaft + Importmap; Turbo + Stimulus controllers in `app/javascript/controllers`.
- Tailwind CSS via `tailwindcss-rails`; charts built with Highcharts modules pinned in `config/importmap.rb`.
- Server-rendered views rely on Turbo streams; no Node/webpack—stick to importmap pins and asset helpers.

### Billing, notifications, integrations

- Premium handled through Lemon Squeezy webhooks and Stripe IDs on `User`; premium unlocks tagging, metadata fields, coffee management, older shots, and removal of daily upload limits.
- Airtable integration (OmniAuth) syncs roasters/bags via the `Airtablable` concern; webhook refresh jobs keep data in sync.
- Web push notifications fire on shot creation for subscribed users.

### Testing & security notes

- Minitest with parallelization; FactoryBot and WebMock are available (network blocked in tests by default).
- When adding Airtable table fields, update the Airtable metadata factory stub in `test/factories/airtable_infos.rb` so tests do not issue unstubbed field-creation requests.
- When adding attributes to Airtable-synced models (`Airtablable`), also update the corresponding mapper under `app/models/airtable/` (for example `STANDARD_FIELDS` and `FIELD_OPTIONS`) so sync stays bidirectional. Rich text notes are the deliberate exception: they sit in `OUTBOUND_ONLY_FIELDS` and are pushed to Airtable as plain text, but edits made in Airtable are never synced back.
- Keep secrets in `.env`/Rails credentials or `.mise.toml`; never commit keys or S3/Lemon Squeezy secrets.
- When touching auth/billing/dependencies, run `bin/ci` or at least RuboCop + security checks (Brakeman, Bundler Audit, Importmap audit, Gitleaks).

## Coding style guidelines

See `STYLE.md` for the canonical style rules. Key points for agents:

### Ruby/Rails

- Prefer expanded conditionals over guard clauses for readability.
- Use guard clauses only for early returns at the very top when the main body is non-trivial.
- Do not assign values inside conditionals; assign first, then branch on the result.
- Order methods: class methods, public (with `initialize` first), then `private` methods.
- Order methods vertically by invocation flow (top calls next, etc.).
- Use `!` only when there is a non-`!` counterpart; do not use `!` to signal destructiveness.
- Prefer `return` over `return nil`; use explicit `nil` only when clarity benefits.
- Do not indent method bodies under visibility modifiers; put `private` on its own line.
- Keep controllers thin; call model/domain APIs directly. Services/form objects are allowed but not special.
- Model non-CRUD endpoints as resources, not custom actions on existing resources.
- Prefer job classes that delegate to domain methods; use `_later` and `_now` conventions.

### Imports, modules, and structure

- Shared model behavior: `app/models/concerns` (use `ActiveSupport::Concern` when `included` or `class_methods` are needed).
- Class-scoped modules: `app/models/<class>/` and include into the class (`Shot::Jsonable`).
- Controller mixins: `app/controllers/concerns` (`Authentication`, `Authorization`, etc.).
- App integrations/wrappers: `app/lib` (autoloaded). Keep experiments in `lib/misc`.
- Frontend JS uses Importmap (no Node/Webpack); manage pins in `config/importmap.rb`.

### Formatting and naming

- Ruby: 2-space indent; follow RuboCop `rubocop-rails-omakase` defaults and any local overrides.
- Filenames: Stimulus controllers are kebab-case; controller classes are camelCase identifiers.
- Rails naming conventions apply for classes, modules, and files.
- In JavaScript, prefer one-line early returns whenever they keep the code clear.

### Types and data handling

- Use ActiveRecord validations and types; prefer explicit casting/parsing in models when needed.
- Keep DB access in models; avoid heavy logic in controllers.

### Error handling and control flow

- Avoid exceptions for routine control flow; use validations/return values where possible.
- Use `create!`/`save!` when you want exceptions to bubble; otherwise handle failures explicitly.

### Views and CSS

- For view edits, run `rustywind` and `htmlbeautifier` on changed templates.
- Use Tailwind utility classes (no custom webpack). Respect existing component patterns.
- Avoid time-dependent computed values (for example `Date.current`-based counters) inside cached list/card fragments; prefer persisted fields in cached UI.
- Visualizer is not accessibility-focused: don't add `aria-*`, `role`, or table `scope` attributes, or screen-reader-only (`sr-only`) content. Keep only what a library needs to work (stimulus-autocomplete finds options via `role="option"`).
- Run Prettier on changed JavaScript files.
- Optimize every new or changed web-served image with ImageOptim before committing: `/Applications/ImageOptim.app/Contents/MacOS/ImageOptim path/to/image.png` (rewrites the file in place; wait for the file size to drop).

## Cursor/Copilot rules

- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` files found in this repo.
