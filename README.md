# [Visualizer](https://visualizer.coffee/)

[![Visualizer Status](https://uptime.betterstack.com/status-badges/v3/monitor/wxvy.svg)](https://status.visualizer.coffee/)

![Ruby Tests](https://github.com/miharekar/visualizer/actions/workflows/main.yml/badge.svg)

Visualizer plays nice with [Decent espresso machines](https://decentespresso.com/), [Meticulous](https://www.meticuloushome.com/), [Beanconqueror](https://beanconqueror.com/), [Gaggiuino](https://gaggiuino.github.io/), [GaggiMate](https://gaggimate.eu/), [Smart Espresso Profiler](https://www.naked-portafilter.com/product-category/smart-espresso-profiler/), [Pressensor](https://pressensor.com/), and many more devices. The list keeps growing.

Read all about it on [visualizer.coffee](https://visualizer.coffee/).

Application monitoring is sponsored by [AppSignal](https://appsignal.com/).

## Getting help

If you have questions, concerns, bug reports, etc., please open a new [GitHub Issue](https://github.com/miharekar/visualizer/issues/).

## Getting involved

If you love coffee, want to learn Ruby, or want to help in whatever way you can, you're more than welcome to get involved!

Please read the [Contribution Guidelines](CONTRIBUTING.md) first 😊

## API

There is an API available. If something you would like is not there, please open a new [Issue](https://github.com/miharekar/visualizer/issues/) detailing your wishes.

You can read [the source code](/app/controllers/api) or [the LLM-generated API documentation](https://apidocs.visualizer.coffee).

## Dependencies

- Ruby (Check [.mise.toml](.mise.toml) for specific version)
- Postgres (>= 18)

No other services are required though S3 is expected in `config/storage.yml`.
Feel free to override it for development purposes.

## Self-hosted OpenID Connect

The self-hosted fork can expose an OpenID Connect authorization-code login when
`OIDC_ISSUER`, `OIDC_CLIENT_ID`, and `OIDC_CLIENT_SECRET` are set. Discovery,
state, nonce, and PKCE are enabled by the strategy. Set
`OIDC_REDIRECT_URI` to the exact HTTPS callback registered at the provider; the
default is `${APP_PROTOCOL}://${APP_HOST}/auth/homelab_oidc/callback`.

The callback links an identity by the provider issuer and immutable `sub`
claim. It never links an account by email alone. An existing native session is
required to link a new identity; otherwise a previously linked identity can
sign in. Keep native password and passkey recovery enabled, and keep the OIDC
client secret in the runtime secret store rather than in this repository or an
image.

Set `OIDC_ONLY=true` after validating the native callback to disable public
password registration and expose only the configured OIDC sign-in option to new
users. Existing native recovery accounts remain available for recovery.
