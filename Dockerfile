# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.2
FROM ruby:${RUBY_VERSION}-slim AS base
ENV LANG=C.UTF-8 BUNDLE_PATH=/usr/local/bundle

# System deps: Postgres client, image processing, JS runtime
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential git curl pkg-config libpq-dev libvips nodejs npm && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# --- Builder: install gems + JS deps and precompile assets ---
FROM base AS builder
COPY Gemfile Gemfile.lock ./
RUN bundle config set deployment 'true' && \
    bundle config set without 'development test' && \
    bundle install --jobs 4

COPY package.json package-lock.json* ./
RUN test -f package.json && npm ci || true

COPY . .
ENV RAILS_ENV=production
RUN bundle exec rake assets:precompile

# --- Runtime: slim runtime image ---
FROM base AS runtime
ENV RAILS_ENV=production RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app
EXPOSE 3000
CMD bash -lc "bin/rails db:migrate && bin/rails server -b 0.0.0.0 -p 3000"
