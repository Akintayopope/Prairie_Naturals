# syntax=docker/dockerfile:1
FROM ruby:3.3-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git pkg-config libpq-dev libvips curl \
  && rm -rf /var/lib/apt/lists/*

RUN gem update --system && gem install bundler -v 2.7.1

ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLE_DEPLOYMENT="1"
WORKDIR /app

# Install gems with only Gemfile* to keep cache stable
COPY Gemfile Gemfile.lock ./
RUN bundle lock --add-platform ruby --add-platform x86_64-linux || true
RUN bundle install --jobs 4

# Now copy the app and precompile
COPY . .
ENV SECRET_KEY_BASE_DUMMY=1
RUN bundle exec rake assets:precompile

FROM ruby:3.3-slim
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libpq-dev libvips \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /app /app

ENV RAILS_ENV=production
ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLE_DEPLOYMENT="1"

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
