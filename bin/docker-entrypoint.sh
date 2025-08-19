#!/usr/bin/env bash
set -euo pipefail

echo "RAILS_ENV=${RAILS_ENV:-development}"

# Ensure tmp dirs exist
mkdir -p tmp/pids tmp/cache tmp/sockets

echo "Migrating..."
bundle exec rails db:prepare

# Seed only in dev or when explicitly requested
if [[ "${SEED_ON_BOOT:-}" == "1" || "${RAILS_ENV:-development}" == "development" ]]; then
  echo "Seeding (guarded)…"
  bundle exec rails db:seed
fi

echo "Booting Puma…"
exec bundle exec puma -C config/puma.rb
