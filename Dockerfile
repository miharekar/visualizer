# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.2.2
FROM ruby:$RUBY_VERSION-slim as base

# Rails app lives here
WORKDIR /rails

ENV RUNTIME_DEPS="curl gnupg2 libvips libvips-dev tzdata librsvg2-dev postgresql-client" \
  BUILD_DEPS="build-essential libpq-dev git less pkg-config python-is-python3 vim rsync"

# Throw-away build stage to reduce size of final image
FROM base as build

# Common dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=tmpfs,target=/var/log \
  rm -f /etc/apt/apt.conf.d/docker-clean; \
  echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache; \
  apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends $BUILD_DEPS $RUNTIME_DEPS

# COPY Aptfile /tmp/Aptfile
# RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
#   --mount=type=cache,target=/var/lib/apt,sharing=locked \
#   --mount=type=tmpfs,target=/var/log \
#   apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
#   DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
#     $(grep -Ev '^\s*#' /tmp/Aptfile | xargs)

# Set production environment
ENV RAILS_ENV="production" \
  BUNDLE_DEPLOYMENT="1" \
  BUNDLE_PATH="/usr/local/bundle" \
  BUNDLE_JOBS="4" \
  BUNDLE_NO_CACHE="true" \
  BUNDLE_WITHOUT="development,test" \
  GEM_HOME="/usr/local/bundle"

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN --mount=type=cache,target=~/.bundle/cache \
  bundle config --local deployment 'true' \
  && bundle config --local path "${BUNDLE_PATH}" \
  && bundle install \
  && rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git \
  && bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

ARG DATABASE_URL="postgres://postgres:postgres@db:5432/postgres"

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
# Mount node_modules and tmp/cache as cache volume:
RUN --mount=type=cache,target=/rails/tmp/cache/assets \
  --mount=type=cache,target=/rails/tmp/assets_between_runs \
  mkdir -p /rails/log && \
  mkdir -p /rails/tmp/assets_between_runs/assets /rails/public/assets && rsync -a /rails/tmp/assets_between_runs/assets/. /rails/public/assets/. && \
  SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile && \
  rsync -a /rails/public/assets/. /rails/tmp/assets_between_runs/assets/.

# Final stage for app image
FROM base as app

# Install packages needed for deployment
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  --mount=type=tmpfs,target=/var/log \
  apt-get update -qq && \
  apt-get install --no-install-recommends -y $RUNTIME_DEPS cron

# Copy built artifacts: gems, application
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN useradd rails --home /rails --shell /bin/bash && \
  chown -R rails:rails db log tmp
USER rails:rails

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server"]
