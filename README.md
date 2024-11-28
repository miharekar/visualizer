# [Visualizer](https://visualizer.coffee/)

[![Visualizer Status](https://uptime.betterstack.com/status-badges/v3/monitor/wxvy.svg)](https://status.visualizer.coffee/)

![Ruby Tests](https://github.com/miharekar/visualizer/actions/workflows/main.yml/badge.svg)

Visualizer was designed to work seamlessly with [Decent espresso machines](https://decentespresso.com/). Recently, it has expanded its compatibility to support [Smart Espresso Profiler](https://www.naked-portafilter.com/product-category/smart-espresso-profiler/[), [Pressensor](https://pressensor.com/) and [Beanconqueror](https://beanconqueror.com/). This provides a streamlined experience that caters to a diverse range of coffee enthusiasts, accommodating their preferred devices.

Read all about it on [visualizer.coffee](https://visualizer.coffee/).

Application monitoring is sponsored by [AppSignal](https://appsignal.com/visualizer/admin/api_keys).

## Getting help

If you have questions, concerns, bug reports, etc., please open a new [GitHub Issue](https://github.com/miharekar/visualizer/issues/).

## Getting involved

If you love coffee, want to learn Ruby, or want to help in whatever way you can, you're more than welcome to get involved!

Please read the [Contribution Guidelines](CONTRIBUTING.md) first 😊

## API

There is an API available. If something you would like is not there, please open a new [Issue](https://github.com/miharekar/visualizer/issues/) detailing your wishes.

You can read [the source code](/app/controllers/api) or [the API documentation](https://documenter.getpostman.com/view/2402164/UVC2HUik) provided by [@eriklenaerts](https://github.com/eriklenaerts).

Authenticatication is possible via [OAuth 2.0 authorization code flow](https://www.oauth.com/oauth2-servers/server-side-apps/authorization-code/) with `read`, `upload`, and `write` scopes.
The difference between `upload` and `write` is that `upload` is **only** for uploading shots, and `write` is for everything. This enables you to have a "low danger" scope, so that even if a token is stolen, the worst that can happen is that the attacker can upload shots. But they won't be able to delete them.
All endpoints return JSON.

If you want to create OAuth applications please [contact me](mailto:miha@visualizer.coffee).

## Dependencies

- Ruby (Check [.ruby-version](.ruby-version) for specific version)
  - Bundler (`gem install bundler`)
- Postgres (>= 14)

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

## Star History

<a href="https://star-history.com/#miharekar/visualizer&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=miharekar/visualizer&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=miharekar/visualizer&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=miharekar/visualizer&type=Date" />
 </picture>
</a>