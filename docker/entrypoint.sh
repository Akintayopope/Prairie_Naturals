#!/usr/bin/env bash
set -e
# Only run if DB url present
if [ -n "$DATABASE_URL" ]; then
  bundle exec rails db:migrate
fi
exec "$@"
