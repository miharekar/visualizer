# [Decent Visualizer](https://visualizer.coffee/)

![Ruby Tests](https://github.com/miharekar/decent-visualizer/actions/workflows/ruby-tests.yml/badge.svg)

A visualizer for `.shot` files created by the [Decent Espresso Machine](https://decentespresso.com/).

Visualizer is a relatively standard [Ruby on Rails](https://rubyonrails.org/) application with a [Postgres](https://www.postgresql.org/) database.

Read [all about v2 version](https://public.3.basecamp.com/p/y8keyN8VrToTNwXw84ZvC2p1) and feel free to [join Visualizer Forum](https://decentforum.com/tag/visualizer).

[![](sample.png)](https://visualizer.coffee/shots/77152920-e5f5-4fd9-a54c-e84133ea1d3e)

### Dependencies

- Ruby (Check [.ruby-version](.ruby-version) for specific version)
  - Bundler (`gem install bundler`)
- Postgres (>= 12)
- Node (Only needed for rebuilding assets)

### Configuration

For local development, there is nothing to configure.

When it comes to deploying, you will need to set some environment variables, namely:

- CLOUDINARY_URL
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- BUCKET_URL

### Setup

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

### Running

```shell
$ ./bin/rails server
```

### How to test

```shell
$ ./bin/rails test
```

### Getting help

If you have questions, concerns, bug reports, etc, please open a new [GitHub Issue](https://github.com/miharekar/decent-visualizer/issues/).

### Getting involved

If you're a coffee fanatic, own a Decent Espresso machine, want to learn Ruby, or want to help in whatever way you can, then you're welcomed to get involved!

But please read the [Contribution Guidelines](CONTRIBUTING.md) first 😊
