# [Decent Visualizer](https://visualizer.coffee/)

![Ruby Tests](https://github.com/miharekar/decent-visualizer/actions/workflows/ruby-tests.yml/badge.svg)

A visualizer for `.shot` files created by the [Decent Espresso Machine](https://decentespresso.com/).

Visualizer is a relatively standard [Ruby on Rails](https://rubyonrails.org/) application with a [Postgres](https://www.postgresql.org/) database.

Read [all about the v2 version](https://public.3.basecamp.com/p/y8keyN8VrToTNwXw84ZvC2p1), and feel free to [join Visualizer Forum](https://decentforum.com/tag/visualizer).

[![](sample.png)](https://visualizer.coffee/shots/77152920-e5f5-4fd9-a54c-e84133ea1d3e)

## API

There is an API available. If something you would like is not there, please open a new [Issue](https://github.com/miharekar/decent-visualizer/issues/) detailing your wishes.

You can read [the source code](/app/controllers/api) or [the API documentation](https://documenter.getpostman.com/view/2402164/UVC2HUik) provided by [@eriklenaerts](https://github.com/eriklenaerts).

Authenticatication is possible via [OAuth 2.0 authorization code flow](https://www.oauth.com/oauth2-servers/server-side-apps/authorization-code/) with `read`, `upload`, and `write` scopes.
The difference between `upload` and `write` is that `upload` is **only** for uploading shots, and `write` is for everything. This enables you to have a "low danger" scope, so that even if a token is stolen, the worst that can happen is that the attacker can upload shots. But they won't be able to delete them.
All endpoints return JSON.

If you want to create OAuth applications please [contact me](mailto:miha@mr.si).

## Dependencies

- Ruby (Check [.ruby-version](.ruby-version) for specific version)
  - Bundler (`gem install bundler`)
- Postgres (>= 12)
- Redis (>= 6)

## Configuration

For local development, there is nothing to configure.

When it comes to deploying, you will need to set some environment variables, namely:

- CLOUDINARY_URL
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION

## Setup

- Install Ruby gems
  ```shell
  $ bundle install
  ```
- Setup database
  ```shell
  $ ./bin/rails db:setup
  ```
- Running the server
  ```shell
  $ ./bin/dev
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
