# [Decent Visualizer](https://visualizer.coffee/)

![Ruby Tests](https://github.com/miharekar/decent-visualizer/actions/workflows/ruby-tests.yml/badge.svg)

A visualizer for `.shot` files created by the [Decent Espresso Machine](https://decentespresso.com/).

Visualizer is a relatively standard [Ruby on Rails](https://rubyonrails.org/) application with a [Postgres](https://www.postgresql.org/) database.

Read [all about the v2 version](https://public.3.basecamp.com/p/y8keyN8VrToTNwXw84ZvC2p1), and feel free to [join Visualizer Forum](https://decentforum.com/tag/visualizer).

[![](sample.png)](https://visualizer.coffee/shots/77152920-e5f5-4fd9-a54c-e84133ea1d3e)

## API

There is a basic API available. If you can read Rails, [this should be pretty self-explanatory](app/controllers/api/shots_controller.rb).

Endpoints available:

- index on `/api/shots/`. Accepts `limit` and `offset` params. Returns authenticated user's or public (if not authenticated) shots ordered by when the shot was created.
- download on `/api/shots/[shot_id]/download`. Accepts `essentials` param. Returns all of the data of the `[shot_id]` shot. If the `essentials` param has any value, it omits data and timeframe values.
- profile on `/api/shots/[shot_id]/download`. Returns the `tcl` profile file of the shot.
- shared on `/api/shots/shared`. Requires `code` param. Returns the shot that is being shared via the 4-character code.
- upload on `/api/shots/upload`. Requires `file` param containing `tcl` (`.shot`) or `JSON` file of the shot. Returns uploaded shot's ID if parsing is successful. Must be authenticated.

Authenticatication is possible via [Basic access](https://en.wikipedia.org/wiki/Basic_access_authentication) with email and password.

All endpoints return JSON.

## Dependencies

- Ruby (Check [.ruby-version](.ruby-version) for specific version)
  - Bundler (`gem install bundler`)
- Postgres (>= 12)
- Node (Only needed for rebuilding assets)

## Configuration

For local development, there is nothing to configure.

When it comes to deploying, you will need to set some environment variables, namely:

- CLOUDINARY_URL
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- BUCKET_URL

## Setup

- Install Ruby gems
  ```shell
  $ bundle install
  ```
- Setup database
  ```shell
  $ ./bin/rails db:setup
  ```
- Rebuild assets (optional)
  ```shell
  $ yarn install
  $ ./bin/rails css_assets:build
  ```
- Running the server
  ```shell
  $ ./bin/rails server
  ```
- Running the tests
  ```shell
  $ ./bin/rails test
  ```

## Getting help

If you have questions, concerns, bug reports, etc., please open a new [GitHub Issue](https://github.com/miharekar/decent-visualizer/issues/).

## Getting involved

If you're a coffee fanatic, own a Decent Espresso machine, want to learn Ruby, or want to help in whatever way you can, you're more than welcome to get involved!

But please read the [Contribution Guidelines](CONTRIBUTING.md) first 😊
