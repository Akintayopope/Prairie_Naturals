# syntax=docker/dockerfile:1.6
# ---------- Builder ----------
FROM ruby:3.3-slim AS builder

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Match your lockfile's Bundler
ENV BUNDLER_VERSION=2.6.9
RUN gem install bundler -v "$BUNDLER_VERSION"

# Bundler (deployment mode; cache tarballs only)
ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_PATH=/usr/local/bundle

WORKDIR /app

# Build deps for gems with native extensions + Postgres
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential pkg-config git curl ca-certificates \
      libpq-dev libyaml-dev tzdata \
    && rm -rf /var/lib/apt/lists/*

# If you use jsbundling/esbuild/webpack, uncomment Node install
# RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
#  && apt-get install -y --no-install-recommends nodejs \
#  && rm -rf /var/lib/apt/lists/*

# Keep this layer cacheable
COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform ruby --add-platform x86_64-linux || true

# Use a cache mount for gem tarballs
RUN --mount=type=cache,target=/usr/local/bundle/cache \
    bundle _${BUNDLER_VERSION}_ install --jobs=4 --retry=3

# Bring in the app code
COPY . .

# Precompile assets at build time (don’t require DB here)
ARG SECRET_KEY_BASE_DUMMY=1
ENV RAILS_ENV=production
# If any initializer touches the DB, guard it on SKIP_DB_ON_BUILD
ENV SKIP_DB_ON_BUILD=1
RUN bundle exec rails assets:precompile

# ---------- Runtime ----------
FROM ruby:3.3-slim

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Minimal runtime libs (libpq for pg, libvips for ActiveStorage variants)
RUN apt-get update && apt-get install -y --no-install-recommends \
      libpq5 libyaml-0-2 libvips tzdata curl ca-certificates \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && rm -rf /var/lib/apt/lists/*

# (Optional) silence discordrb "libsodium not available" by installing:
# RUN apt-get update && apt-get install -y --no-install-recommends libsodium23 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Bundler + app from builder
ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_PATH=/usr/local/bundle
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

# Rails runtime env
ENV RAILS_ENV=production RACK_ENV=production \
    RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1 \
    PORT=3000

# Entrypoint boots DB, seeds (opt-in), then Puma
ENTRYPOINT ["bash","bin/docker-entrypoint.sh"]
CMD ["bundle","exec","puma","-C","config/puma.rb"]

EXPOSE 3000
