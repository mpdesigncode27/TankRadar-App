#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ -f "$ROOT/.env.asc.local" ]]; then
  # shellcheck disable=SC1091
  source "$ROOT/.env.asc.local"
fi

exec bundle exec fastlane "$@"
