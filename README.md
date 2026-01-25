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
