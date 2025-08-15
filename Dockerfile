# syntax=docker/dockerfile:1.7-labs
FROM ruby:3.3-slim AS builder

# Match your lockfile's Bundler
ENV BUNDLER_VERSION=2.6.9
RUN gem install bundler -v "$BUNDLER_VERSION"

# Bundler installs into a real layer; we'll cache only tarballs
ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_PATH=/usr/local/bundle

WORKDIR /app

# ✅ Native build deps BEFORE bundle install
# libyaml-dev (+pkg-config, build-essential) fixes psych (yaml.h)
# libpq-dev is for pg; keep others minimal
RUN apt-get update -y && apt-get install -y --no-install-recommends \
      build-essential pkg-config git curl ca-certificates \
      libyaml-dev libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Keep this layer cacheable
COPY Gemfile Gemfile.lock ./

# Ensure linux platforms are present for Docker builds
RUN bundle lock --add-platform ruby --add-platform x86_64-linux || true

# Cache only the gem tarballs; installed gems persist in image
RUN --mount=type=cache,target=/usr/local/bundle/cache \
    bundle _${BUNDLER_VERSION}_ install --jobs=${BUNDLE_JOBS:-4} --retry=${BUNDLE_RETRY:-3}

# Bring in the app
COPY . .

# --- Runtime stage ---
FROM ruby:3.3-slim
WORKDIR /app

# ✅ Tell bundler we're in deployment mode and to skip dev/test at runtime too
ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development test" \
    BUNDLE_PATH=/usr/local/bundle

RUN apt-get update -y && apt-get install -y --no-install-recommends \
      libyaml-0-2 libpq5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

ENV RAILS_ENV=production RACK_ENV=production RAILS_LOG_TO_STDOUT=1 PORT=3000
EXPOSE 3000
CMD ["bash","-lc","bundle exec rails server -b 0.0.0.0 -p ${PORT:-3000}"]
